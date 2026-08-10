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
}

run "naming_convention" {
  command = plan

  variables {
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
  }

  assert {
    condition     = azurerm_container_app_environment.env["test"].name == "Dev-OPS-CORE-test-cae"
    error_message = "Environment name must follow {env}-{group}-{project}-{key}-cae convention"
  }
  assert {
    condition     = azurerm_user_assigned_identity.environment["test"].name == "Dev-OPS-CORE-test-cae-umi"
    error_message = "UMI name must follow {env}-{group}-{project}-{key}-cae-umi convention"
  }
}

run "default_values" {
  command = plan

  variables {
    container-app-environment = {
      test = {
        resource_group    = "Project"
        subnet            = "APP"
        registry_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ContainerRegistry/registries/existingacr"
        registry_pull_umi = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-pull-umi"
        workload_profiles = {
          default = { workload_profile_type = "Consumption", minimum_count = 0, maximum_count = 1 }
        }
      }
    }
  }

  assert {
    condition     = azurerm_container_app_environment.env["test"].internal_load_balancer_enabled == true
    error_message = "internal_load_balancer_enabled must default to true"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].zone_redundancy_enabled == null
    error_message = "zone_redundancy_enabled must default to null when not set"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].mutual_tls_enabled == null
    error_message = "mutual_tls_enabled must default to null when not set"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].logs_destination == null
    error_message = "logs_destination must default to null when not set"
  }
  assert {
    condition     = azurerm_user_assigned_identity.environment["test"].isolation_scope == null
    error_message = "isolation_scope must default to null when not set"
  }
}

run "custom_resource_names_and_new_args" {
  command = plan

  variables {
    container-app-environment = {
      test = {
        resource_group                              = "Project"
        subnet                                      = "APP"
        registry_id                                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ContainerRegistry/registries/existingacr"
        registry_pull_umi                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-pull-umi"
        name                                        = "existing-cae-name"
        umi_name                                    = "existing-umi-name"
        umi_isolation_scope                         = "Regional"
        zone_redundancy_enabled                     = true
        mutual_tls_enabled                          = true
        public_network_access                       = "Disabled"
        logs_destination                            = "log-analytics"
        log_analytics_workspace_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-project/providers/Microsoft.OperationalInsights/workspaces/law"
        infrastructure_resource_group_name          = "rg-infra"
        dapr_application_insights_connection_string = "InstrumentationKey=00000000-0000-0000-0000-000000000000"
        workload_profiles = {
          default = { workload_profile_type = "D4", minimum_count = 0, maximum_count = 1 }
        }
      }
    }
  }

  assert {
    condition     = azurerm_container_app_environment.env["test"].name == "existing-cae-name"
    error_message = "name override not applied"
  }
  assert {
    condition     = azurerm_user_assigned_identity.environment["test"].name == "existing-umi-name"
    error_message = "umi_name override not applied"
  }
  assert {
    condition     = azurerm_user_assigned_identity.environment["test"].isolation_scope == "Regional"
    error_message = "umi_isolation_scope not applied"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].zone_redundancy_enabled == true
    error_message = "zone_redundancy_enabled not applied"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].mutual_tls_enabled == true
    error_message = "mutual_tls_enabled not applied"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].public_network_access == "Disabled"
    error_message = "public_network_access not applied"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].logs_destination == "log-analytics"
    error_message = "logs_destination not applied"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].infrastructure_resource_group_name == "rg-infra"
    error_message = "infrastructure_resource_group_name not applied"
  }
  assert {
    condition     = azurerm_container_app_environment.env["test"].dapr_application_insights_connection_string == "InstrumentationKey=00000000-0000-0000-0000-000000000000"
    error_message = "dapr_application_insights_connection_string not applied"
  }
}

run "additional_identity_ids" {
  command = apply

  override_resource {
    target = azurerm_user_assigned_identity.environment["test"]
    values = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/rg-project/providers/Microsoft.ManagedIdentity/userAssignedIdentities/Dev-OPS-CORE-test-cae-umi"
    }
  }

  variables {
    container-app-environment = {
      test = {
        resource_group    = "Project"
        subnet            = "APP"
        registry_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ContainerRegistry/registries/existingacr"
        registry_pull_umi = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-pull-umi"
        additional_identity_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-project/providers/Microsoft.ManagedIdentity/userAssignedIdentities/extra-umi"
        ]
        workload_profiles = {
          default = { workload_profile_type = "D4", minimum_count = 0, maximum_count = 1 }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_container_app_environment.env["test"].identity[0].identity_ids) == 2
    error_message = "additional_identity_ids must be merged with the environment's own UMI"
  }
}
