# config/container-apps.tfvars
# Tracked, ready-to-run fixture for the test/live harness - one representative
# real-usage instance (auto-created registry + private endpoint, a Dedicated
# workload profile, and a single public-image app), not a two-code-path
# engineered fixture and not a dormant "_" template.
#
# Pre-existing module behaviour worked around here (not a module-code fix):
# the workload_profile dynamic block unconditionally sets minimum_count/
# maximum_count regardless of workload_profile_type. Azure's real API
# rejects those fields for a "Consumption" profile
# (WorkloadProfilePropertyNotSupported, 400) - using "D4" (Dedicated)
# instead avoids that and matches the module's own ESLZ/*.tfvars example.
#
# Maintained by whoever adds a new optional input to the module: update this
# file in the same PR if you want live coverage of it, same discipline as
# updating tests/*.tftest.hcl.

env = "livetest"

container-app-environment = {
  livetest = {
    resource_group = "live_test"
    subnet         = "APP"

    workload_profiles = {
      default = {
        workload_profile_type = "D4"
        minimum_count         = 0
        maximum_count         = 1
      }
    }

    registry_private_endpoint_subnet = "RZ"
  }
}

container-app = {
  livetest = {
    resource_group             = "live_test"
    container-app-environment  = "livetest"

    image                  = "nginx:latest"
    cpu                    = 0.25
    memory                 = "0.5Gi"
    workload_profile_name  = "default"

    ingress_target_port      = 80
    ingress_external_enabled = true
  }
}
