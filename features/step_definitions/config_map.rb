require 'yaml'

Given /^value of #{QUOTED} in configmap #{QUOTED} as YAML is merged with:$/ do |key, cm_name, yaml|
  current_content = YAML.load config_map(cm_name).value_of(key)
  to_merge_content = YAML.load yaml

  deep_merge!(current_content, to_merge_content)

  config_map(cm_name).set_value(key, current_content.to_yaml, user: user)
end

Given /^I store the leader node name from the #{QUOTED} configmap to the#{OPT_SYM} clipboard$/ do | cm_name, cb_name |

  cb_name ||= "holderIdentity"
  rr = config_map(cm_name).raw_resource
  leader_str = rr.dig('metadata', 'annotations', 'control-plane.alpha.kubernetes.io/leader')
  leader_yaml = YAML.load(leader_str)
  cb[cb_name] = leader_yaml.dig("holderIdentity")

end
# 1. download file from JSON/YAML URL
# 2. specify specific key/values on different versions
# 3. replace any path with given value from table
# 4. runs `oc create` command over the resulting file
When /^I create a configmap from #{QUOTED} replacing paths:$/ do |file, table|
  if file.include? '://'
    step %Q|I download a file from "#{file}"|
    resource_hash = YAML.load(@result[:response])
  else
    resource_hash = YAML.load_file(expand_path(file))
  end

  # replace paths from table
  table.raw.each do |path, value|
    eval "resource_hash#{path} = YAML.load value"
    # e.g. resource["spec"]["name"] = myname
  end

  resource = resource_hash.to_json
  logger.info resource

  @result = user.cli_exec(:create, {f: "-", _stdin: resource})
end

# check the configmap status
Given /^the#{OPT_QUOTED} becomes #{SYM}(?: within (\d+) seconds)?$/ do |configmap_name, status, timeout|
  timeout = timeout ? timeout.to_i : 30
  @result = configmap(configmap_name).wait_till_status(status.to_sym, user, timeout)

  unless @result[:success]
    user.cli_exec(:get, resource: "configmap", resource_name: "#{configmap_name}", o: "yaml")
    user.cli_exec(:describe, resource: "configmap", name: "#{configmap_name}")
    raise "configmap #{configmap_name} never reached status: #{status}"
  end
end
