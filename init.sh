#!/bin/bash

cp "$HOME"/.kube/config ~/.kube/configbak
rm -f "$HOME"/proxy_env/client_proxy_setting.sh
source "$HOME"/proxy_env/unset
curl -ks  https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/"$1"/artifact/workdir/install-dir/auth/kubeconfig > ~/.kube/config
hosts=$(curl -ks https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/"$1"/artifact/host.spec/*view*/)
proxyFlag=$(echo "$hosts" | cut -f2 -d ':')
# echo "$proxyFlag"
if [ "$proxyFlag" != "lb" ];
then
  # Set proxy for: vSphere cluster, Azure private cluster(private-templates/functionality-testing/aos-4_10/ipi-on-azure/versioned-installer-fully_private_cluster-NAT)
  # https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/76497/artifact/workdir/install-dir/client_proxy_setting.sh/*view*
#   curl -ks https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/"$1"/artifact/workdir/install-dir/client_proxy_setting.sh/*view*/
  curl -ks -o "$HOME"/proxy_env/client_proxy_setting.sh https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/"$1"/artifact/workdir/install-dir/client_proxy_setting.sh
  source "$HOME"/proxy_env/client_proxy_setting.sh
fi
version=$(oc version -o json | jq -r '.openshiftVersion' | awk -F '.' '{print $1"."$2}')
echo "* Clusterversion: $(oc get clusterversion --no-headers| awk '{print $9}') * Platform: $(oc get infrastructure cluster -o=jsonpath='{.status.platform}') * NetWorking: $(oc get network.operator cluster -o=jsonpath='{.spec.defaultNetwork.type}') *"
source "$HOME"/proxy_env/unset

# Init myocp ENV
echo "" > myocp
# Set default environment
echo "export BUSHSLICER_DEFAULT_ENVIRONMENT=ocp4" > myocp
# Get cluster credential
echo "export OPENSHIFT_ENV_OCP4_ADMIN_CREDS_SPEC=\"https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/$1/artifact/workdir/install-dir/auth/kubeconfig\"" >> myocp
# Set cluster client version
echo "export BUSHSLICER_CONFIG='{\"environments\": {\"ocp4\": {\"version\": \"$version\"}}}'" >> myocp
# Get cluster common users
echo "export OPENSHIFT_ENV_OCP4_USER_MANAGER_USERS=\"`curl -s https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/$1/artifact/users.spec/*view*/`\"" >> myocp
# Get cluster host lb
echo "export OPENSHIFT_ENV_OCP4_HOSTS=`curl -s https://mastern-jenkins-csb-openshift-qe.apps.ocp-c1.prod.psi.redhat.com/job/ocp-common/job/Flexy-install/$1/artifact/host.spec/*view*/`" >> myocp
# Refresh ENV 
source myocp
echo "BUSHSLICER_DEFAULT_ENVIRONMENT="$BUSHSLICER_DEFAULT_ENVIRONMENT
echo "OPENSHIFT_ENV_OCP4_ADMIN_CREDS_SPEC="$OPENSHIFT_ENV_OCP4_ADMIN_CREDS_SPEC
echo "BUSHSLICER_CONFIG="$BUSHSLICER_CONFIG
echo "OPENSHIFT_ENV_OCP4_USER_MANAGER_USERS="$OPENSHIFT_ENV_OCP4_USER_MANAGER_USERS
echo "OPENSHIFT_ENV_OCP4_HOSTS="$OPENSHIFT_ENV_OCP4_HOSTS