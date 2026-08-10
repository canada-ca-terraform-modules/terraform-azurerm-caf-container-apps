locals {
  app_umi_id_map = {
    for key, app in var.container-app :
    key => try(
      var.container-app-environment[app.container-app-environment].registry_pull_umi,
      try(module.containerRegistry[app.container-app-environment].acr-pull-umi[0].id, null)
    )
  }

  app_registry_map = {
    for key, app in var.container-app :
    key => try(
      data.azapi_resource.existing_registry[app.container-app-environment].output,
      module.containerRegistry[app.container-app-environment].container-registry-object
    )
  }

  app_resource_group_names = {
    for key, app in var.container-app :
    key => (
      strcontains(app.resource_group, "/resourceGroups/")
      ? split("/resourceGroups/", app.resource_group)[1]
      : var.resource_groups[app.resource_group].name
    )
  }
}

resource "azurerm_container_app" "apps" {
  for_each = var.container-app

  name                         = try(each.value.name, each.key)
  container_app_environment_id = azurerm_container_app_environment.env[each.value.container-app-environment].id
  resource_group_name          = local.app_resource_group_names[each.key]
  revision_mode                = "Single"
  workload_profile_name        = each.value.workload_profile_name
  max_inactive_revisions       = try(each.value.max_inactive_revisions, null)

  registry {
    server   = local.app_registry_map[each.key].login_server
    identity = local.app_umi_id_map[each.key]
  }

  dynamic "secret" {
    for_each = try(each.value.secrets, {})

    content {
      name                = secret.key
      value               = try(secret.value.value, null)
      identity            = try(secret.value.identity, null)
      key_vault_secret_id = try(secret.value.key_vault_secret_id, null)
    }
  }

  dynamic "dapr" {
    for_each = try(each.value.dapr, null) != null ? [each.value.dapr] : []

    content {
      app_id       = dapr.value.app_id
      app_port     = try(dapr.value.app_port, null)
      app_protocol = try(dapr.value.app_protocol, "http")
    }
  }

  template {
    min_replicas = try(each.value.min_replicas, null)
    max_replicas = try(each.value.max_replicas, null)

    container {
      name   = each.key
      image  = "${local.app_registry_map[each.key].login_server}/${each.value.image}"
      cpu    = each.value.cpu
      memory = each.value.memory

      dynamic "env" {
        for_each = try(each.value.env, {})

        content {
          name  = env.key
          value = env.value
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = try(each.value.http_scale_rules, { http-scaler = { concurrent_requests = 10 } })

      content {
        name                = http_scale_rule.key
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = try(http_scale_rule.value.authentication, {})

          content {
            secret_name       = authentication.key
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }
  }

  ingress {
    target_port                = each.value.ingress_target_port
    exposed_port               = try(each.value.ingress_exposed_port, null)
    external_enabled           = try(each.value.ingress_external_enabled, true)
    allow_insecure_connections = try(each.value.ingress_allow_insecure_connections, null)
    transport                  = try(each.value.ingress_transport, null)

    client_certificate_mode = "ignore"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }

    dynamic "ip_security_restriction" {
      for_each = try(each.value.ip_security_restrictions, {})

      content {
        name             = ip_security_restriction.key
        action           = ip_security_restriction.value.action
        ip_address_range = ip_security_restriction.value.ip_address_range
        description      = try(ip_security_restriction.value.description, null)
      }
    }

    dynamic "cors" {
      for_each = try(each.value.cors, null) != null ? [each.value.cors] : []

      content {
        allowed_origins           = cors.value.allowed_origins
        allow_credentials_enabled = try(cors.value.allow_credentials_enabled, false)
        allowed_headers           = try(cors.value.allowed_headers, null)
        allowed_methods           = try(cors.value.allowed_methods, null)
        exposed_headers           = try(cors.value.exposed_headers, null)
        max_age_in_seconds        = try(cors.value.max_age_in_seconds, null)
      }
    }
  }

  identity {
    type         = strcontains(try(each.value.identity.type, "UserAssigned"), "SystemAssigned") ? "SystemAssigned, UserAssigned" : "UserAssigned"
    identity_ids = concat(try(each.value.identity.identity_ids, []), [local.app_umi_id_map[each.key]])
  }

  tags = var.tags

  lifecycle {

    precondition {
      condition     = local.app_umi_id_map[each.key] != null
      error_message = "container-app '${each.key}': could not resolve a registry pull identity. When the associated container-app-environment sets 'registry_id' (existing registry), it must also set 'registry_pull_umi'."
    }

    precondition {
      condition     = try(each.value.ingress_exposed_port, null) == null || try(each.value.ingress_transport, null) == "tcp"
      error_message = "container-app '${each.key}': 'ingress_exposed_port' is only valid when 'ingress_transport' = \"tcp\"."
    }

    ignore_changes = [
      # ignore the image as this is expect to be managed by the deployment processes
      template[0].container[0].image
    ]
  }
}

resource "azurerm_container_app_custom_domain" "example" {

  for_each = merge([
    for key, value in var.container-app :
    {
      for domain in try(value.custom_domain_names, []) :
      "${key} ${domain}" => {
        name                                     = domain
        container_app_id                         = azurerm_container_app.apps[key].id
        container_app_environment_certificate_id = azapi_resource.cae-certificate[value.container-app-environment].output.id
      }
      if contains(keys(azapi_resource.cae-certificate), value.container-app-environment)
    }
  ]...)


  name                                     = each.value.name
  container_app_id                         = each.value.container_app_id
  container_app_environment_certificate_id = each.value.container_app_environment_certificate_id
  certificate_binding_type                 = "SniEnabled"
}

# Guards the cases the for_each expression above cannot itself raise a helpful error for:
# an app requesting custom_domain_names whose container-app-environment has no cert_name
# (and therefore no azapi_resource.cae-certificate entry) is silently skipped rather than
# crashing the plan with an "Invalid index" error.
check "custom_domain_requires_certificate" {
  assert {
    condition = alltrue([
      for key, value in var.container-app :
      length(try(value.custom_domain_names, [])) == 0 || contains(keys(azapi_resource.cae-certificate), value.container-app-environment)
    ])
    error_message = "container-app: one or more apps set 'custom_domain_names' but their container-app-environment has no 'cert_name' configured, so no certificate exists to bind. Those custom domains were not created."
  }
}
