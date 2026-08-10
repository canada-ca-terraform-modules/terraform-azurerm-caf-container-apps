mock_provider "azurerm" {}
mock_provider "azapi" {}

variables {
  env      = "Dev"
  group    = "OPS"
  project  = "CORE"
  location = "canadacentral"

  resource_groups = {
    Project = { name = "rg-project", location = "canadacentral" }
  }

  subnets = {
    APP = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-project/providers/Microsoft.Network/virtualNetworks/vnet/subnets/APP" }
  }

  container-app-environment = {
    test = {
      resource_group    = "Project"
      subnet            = "APP"
      registry_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ContainerRegistry/registries/existingacr"
      registry_pull_umi = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-pull-umi"
      workload_profiles = {
        default = { workload_profile_type = "D4", minimum_count = 0, maximum_count = 1 }
      }
    }
  }

  container-app = {
    test = {
      resource_group            = "Project"
      container-app-environment = "test"
      image                     = "nginx:latest"
      cpu                       = 0.25
      memory                    = "0.5Gi"
      workload_profile_name     = "default"
      ingress_target_port       = 80
    }
  }
}

# Step 1: simulate the currently-deployed resources (pre-upgrade inputs, no new args)
run "baseline_apply" {
  command = apply

  override_resource {
    target = azurerm_user_assigned_identity.environment["test"]
    values = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/rg-project/providers/Microsoft.ManagedIdentity/userAssignedIdentities/Dev-OPS-CORE-test-cae-umi"
    }
  }

  override_resource {
    target = azurerm_container_app_environment.env["test"]
    values = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/rg-project/providers/Microsoft.App/managedEnvironments/Dev-OPS-CORE-test-cae"
    }
  }

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  assert {
    condition     = azurerm_container_app_environment.env["test"].name == "Dev-OPS-CORE-test-cae"
    error_message = "Baseline apply: unexpected environment name"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].name == "test"
    error_message = "Baseline apply: unexpected app name"
  }
}

# Step 2: plan the upgraded code (with new azurerm 5.0.1 args added) against that state
run "upgrade_plan_no_replacement" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  variables {
    container-app-environment = {
      test = {
        resource_group          = "Project"
        subnet                  = "APP"
        registry_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ContainerRegistry/registries/existingacr"
        registry_pull_umi       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-pull-umi"
        zone_redundancy_enabled = true
        workload_profiles = {
          default = { workload_profile_type = "D4", minimum_count = 0, maximum_count = 1 }
        }
      }
    }
    container-app = {
      test = {
        resource_group            = "Project"
        container-app-environment = "test"
        image                     = "nginx:latest"
        cpu                       = 0.25
        memory                    = "0.5Gi"
        workload_profile_name     = "default"
        ingress_target_port       = 80
        max_inactive_revisions    = 10
      }
    }
  }

  assert {
    condition     = azurerm_container_app_environment.env["test"].name == "Dev-OPS-CORE-test-cae"
    error_message = "Environment name must be unchanged after upgrade"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].name == "test"
    error_message = "App name must be unchanged after upgrade"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].zone_redundancy_enabled == true
    error_message = "zone_redundancy_enabled must be set after upgrade"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].max_inactive_revisions == 10
    error_message = "max_inactive_revisions must be set after upgrade"
  }
}
