Feature: Immutable Configmap feature
# @author pewang@redhat.com
  @admin
  Scenario: Immutable Configmap feature
    Given I have a project
    Given I obtain test data file "configmap/configmap-example.yaml"
    When I create a configmap from "configmap-example.yaml" replacing paths:
      | ["metadata"]["name"] | my-configmap |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | configmap                                                    |
      | resource_name | my-configmap                                                  |
      | p             | {"data":{"before":"update"}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | configmap                                                    |
      | resource_name | my-configmap                                                  |
      | p             | {"immutable":true} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | configmap                                                    |
      | resource_name | my-configmap                                                  |
      | p             | {"data":{"after":"update"}} |
    Then the expression should be true> @result[:success] == env.version_le("3.5", user: user)
    And the step should fail