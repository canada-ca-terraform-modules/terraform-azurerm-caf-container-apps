locals {
  app_umi_map = {
    for key, app in var.container-app:
      key => module.containerRegistry[app.container-app-environment].acr-pull-umi[0]
  }

  app_registry_map = {
    for key, app in var.container-app:
      key => module.containerRegistry[app.container-app-environment].container-registry-object
  }
}

resource "azurerm_container_app" "apps" {
  for_each = var.container-app

  name = "${each.key}"
  container_app_environment_id = azurerm_container_app_environment.env[each.value.container-app-environment].id
  resource_group_name = var.resource_groups[each.value.resource_group].name
  revision_mode = "Single"
  workload_profile_name = each.value.workload_profile_name

  registry {
    server = local.app_registry_map[each.key].login_server
    identity = local.app_umi_map[each.key].id
  }

  template {
    min_replicas = try(each.value.min_replicas, null)

    container {
      name = "${each.key}"
      image = "${local.app_registry_map[each.key].login_server}/${each.value.image}"
      cpu = each.value.cpu
      memory = each.value.memory
    
      dynamic "env" {
        for_each = try(each.value.env, {})

        content {
          name = env.key
          value = env.value
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = try(each.value.http_scale_rules, { http-scaler = { concurrent_requests = 10 }})

      content {
        name = http_scale_rule.key
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = try(http_scale_rule.authentication, {})

          content {
            secret_name = authentication.key
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }
  }

  ingress {
    target_port = each.value.ingress_target_port
    external_enabled = try(each.value.ingress_external_enabled, true)
    
    client_certificate_mode = "ignore"

    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  identity {
    type = strcontains(try(each.value.identity.type, "UserAssigned"), "SystemAssigned") ? "SystemAssigned, UserAssigned" : "UserAssigned"
    identity_ids = concat(try(each.value.identity.identity_ids, []), [ local.app_umi_map[each.key].id ])
  }

  tags = var.tags
}

resource "azurerm_container_app_custom_domain" "example" {

  for_each = merge([
    for key, value in var.container-app:
    {
      for domain in try(value.custom_domain_names, []):
      "${key} ${domain}" => {
        name = domain
        container_app_id = azurerm_container_app.apps[key].id
        container_app_environment_certificate_id = azapi_resource.cae-certificate[value.container-app-environment].output.id
      }
    }
  ]...)

  
  name                                     = each.value.name
  container_app_id                         = each.value.container_app_id
  container_app_environment_certificate_id = each.value.container_app_environment_certificate_id
  certificate_binding_type                 = "SniEnabled"
}