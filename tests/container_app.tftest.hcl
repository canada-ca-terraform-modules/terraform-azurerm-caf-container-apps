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
    RZ  = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-project/providers/Microsoft.Network/virtualNetworks/vnet/subnets/RZ" }
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
}

run "naming_convention" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  variables {
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

  assert {
    condition     = azurerm_container_app.apps["test"].name == "test"
    error_message = "App name must default to the map key"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].template[0].container[0].image == "existingacr.azurecr.io/nginx:latest"
    error_message = "Container image must be prefixed with the resolved registry login server"
  }
}

run "default_values" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  variables {
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

  assert {
    condition     = azurerm_container_app.apps["test"].revision_mode == "Single"
    error_message = "revision_mode must default to Single"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].ingress[0].external_enabled == true
    error_message = "ingress_external_enabled must default to true"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].max_inactive_revisions == null
    error_message = "max_inactive_revisions must default to null when not set"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].template[0].max_replicas == null
    error_message = "max_replicas must default to null when not set"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].ingress[0].transport == null
    error_message = "ingress_transport must default to null when not set"
  }
}

run "custom_resource_name_and_new_args" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  variables {
    container-app = {
      test = {
        resource_group                     = "Project"
        container-app-environment          = "test"
        name                               = "existing-app-name"
        image                              = "nginx:latest"
        cpu                                = 0.25
        memory                             = "0.5Gi"
        workload_profile_name              = "default"
        ingress_target_port                = 80
        max_inactive_revisions             = 10
        max_replicas                       = 3
        ingress_transport                  = "http2"
        ingress_allow_insecure_connections = true
        ip_security_restrictions = {
          allow-office = {
            action           = "Allow"
            ip_address_range = "1.2.3.4/32"
          }
        }
        cors = {
          allowed_origins = ["https://example.com"]
        }
        secrets = {
          my-secret = { value = "super-secret" }
        }
        dapr = {
          app_id   = "my-app"
          app_port = 8080
        }
      }
    }
  }

  assert {
    condition     = azurerm_container_app.apps["test"].name == "existing-app-name"
    error_message = "name override not applied"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].max_inactive_revisions == 10
    error_message = "max_inactive_revisions not applied"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].template[0].max_replicas == 3
    error_message = "max_replicas not applied"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].ingress[0].transport == "http2"
    error_message = "ingress_transport not applied"
  }
  assert {
    condition     = azurerm_container_app.apps["test"].ingress[0].allow_insecure_connections == true
    error_message = "ingress_allow_insecure_connections not applied"
  }
  assert {
    condition     = tolist(azurerm_container_app.apps["test"].ingress[0].ip_security_restriction)[0].action == "Allow"
    error_message = "ip_security_restrictions not applied"
  }
  assert {
    condition     = tolist(azurerm_container_app.apps["test"].ingress[0].cors)[0].allowed_origins[0] == "https://example.com"
    error_message = "cors not applied"
  }
  assert {
    condition     = tolist(azurerm_container_app.apps["test"].secret)[0].name == "my-secret"
    error_message = "secrets not applied"
  }
  assert {
    condition     = tolist(azurerm_container_app.apps["test"].dapr)[0].app_id == "my-app"
    error_message = "dapr not applied"
  }
}

run "http_scale_rule_authentication" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  variables {
    container-app = {
      test = {
        resource_group            = "Project"
        container-app-environment = "test"
        image                     = "nginx:latest"
        cpu                       = 0.25
        memory                    = "0.5Gi"
        workload_profile_name     = "default"
        ingress_target_port       = 80
        http_scale_rules = {
          custom-scaler = {
            concurrent_requests = 25
            authentication = {
              my-secret = { trigger_parameter = "connectionString" }
            }
          }
        }
        secrets = {
          my-secret = { value = "super-secret" }
        }
      }
    }
  }

  # Regression check: the authentication dynamic block must reference
  # http_scale_rule.value.authentication, not http_scale_rule.authentication
  # (the outer dynamic-block iterator only exposes .key/.value)
  assert {
    condition     = tolist(tolist(azurerm_container_app.apps["test"].template[0].http_scale_rule)[0].authentication)[0].secret_name == "my-secret"
    error_message = "authentication.secret_name must resolve to the map key"
  }
  assert {
    condition     = tolist(tolist(azurerm_container_app.apps["test"].template[0].http_scale_rule)[0].authentication)[0].trigger_parameter == "connectionString"
    error_message = "authentication.trigger_parameter must resolve correctly"
  }
}

run "custom_domain" {
  command = plan

  override_data {
    target = data.azapi_resource.existing_registry["test"]
    values = {
      output = { login_server = "existingacr.azurecr.io" }
    }
  }

  variables {
    keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-project/providers/Microsoft.KeyVault/vaults/kv-project"
    container-app-environment = {
      test = {
        resource_group    = "Project"
        subnet            = "APP"
        registry_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ContainerRegistry/registries/existingacr"
        registry_pull_umi = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-registry/providers/Microsoft.ManagedIdentity/userAssignedIdentities/acr-pull-umi"
        cert_name         = "my-cert"
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
        custom_domain_names       = ["app.example.com"]
      }
    }
  }

  assert {
    condition     = azurerm_container_app_custom_domain.example["test app.example.com"].name == "app.example.com"
    error_message = "custom domain resource must be keyed by \"<app> <domain>\" and expose the domain name"
  }
}
