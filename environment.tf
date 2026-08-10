locals {

  container_app_resource_group_names = {
    for key, value in var.container-app-environment :
    key => (
      strcontains(value.resource_group, "/resourceGroups/")
      ? split("/resourceGroups/", value.resource_group)[1]
      : var.resource_groups[value.resource_group].name
    )
  }

  container_app_subnet_ids = {
    for key, value in var.container-app-environment :
    key => (
      strcontains(value.subnet, "/subnets/")
      ? value.subnet
      : var.subnets[value.subnet].id
    )
  }
}

resource "azurerm_user_assigned_identity" "environment" {
  for_each = var.container-app-environment

  name                = try(each.value.umi_name, "${var.env}-${var.group}-${var.project}-${each.key}-cae-umi")
  resource_group_name = local.container_app_resource_group_names[each.key]
  location            = var.location
  isolation_scope     = try(each.value.umi_isolation_scope, null)
  tags                = var.tags
}

resource "azurerm_container_app_environment" "env" {
  for_each = var.container-app-environment

  name                = try(each.value.name, "${var.env}-${var.group}-${var.project}-${each.key}-cae")
  location            = var.location
  resource_group_name = local.container_app_resource_group_names[each.key]

  infrastructure_subnet_id                    = local.container_app_subnet_ids[each.key]
  infrastructure_resource_group_name          = try(each.value.infrastructure_resource_group_name, null)
  internal_load_balancer_enabled              = try(each.value.internal_load_balancer_enabled, true)
  zone_redundancy_enabled                     = try(each.value.zone_redundancy_enabled, null)
  mutual_tls_enabled                          = try(each.value.mutual_tls_enabled, null)
  public_network_access                       = try(each.value.public_network_access, null)
  logs_destination                            = try(each.value.logs_destination, try(each.value.log_analytics_workspace_id, null) != null ? "log-analytics" : null, null)
  dapr_application_insights_connection_string = try(each.value.dapr_application_insights_connection_string, null)

  identity {
    type = "UserAssigned"
    identity_ids = distinct(concat(
      [azurerm_user_assigned_identity.environment[each.key].id],
      try(each.value.additional_identity_ids != null ? each.value.additional_identity_ids : [], []),
      try(each.value.additional_identity_id != null ? [each.value.additional_identity_id] : [], [])
    ))
  }

  dynamic "workload_profile" {
    for_each = each.value.workload_profiles

    content {
      name                  = workload_profile.key
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  tags = var.tags

  log_analytics_workspace_id = try(each.value.log_analytics_workspace_id, null)

  lifecycle {
    ignore_changes = [infrastructure_resource_group_name]

    precondition {
      condition     = !(try(each.value.internal_load_balancer_enabled, true) == true && try(each.value.public_network_access, null) == "Enabled")
      error_message = "container-app-environment '${each.key}': 'public_network_access = \"Enabled\"' has no effect while 'internal_load_balancer_enabled' is true (the default). Set 'internal_load_balancer_enabled = false' to expose the environment publicly."
    }
  }
}
