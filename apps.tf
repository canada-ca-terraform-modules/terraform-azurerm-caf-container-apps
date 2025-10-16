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
    container {
      name = "${each.key}"
      image = "${module.containerRegistry[each.key].container-registry-object.login_server}/${each.value.image}"
      cpu = each.value.cpu
      memory = each.value.memory
    }
  }

  ingress {
    target_port = each.value.ingress_target_port
    external_enabled = true
    client_certificate_mode = "ignore"

    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
  identity {
    type = "UserAssigned"
    identity_ids = [ local.app_umi_map[each.key].id ] 
  }

  tags = var.tags
}

resource "azurerm_container_app_custom_domain" "example" {

  for_each = merge([
    for key, value in var.container-app:
    {
      for domain in value.custom_domain_names:
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