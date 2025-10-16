resource "azurerm_user_assigned_identity" "environment" {
  for_each = var.container-app-environment

  name = "${var.env}-${var.group}-${var.project}-${each.key}-cae-umi"
  resource_group_name = var.resource_groups[each.value.resource_group].name
  location = var.location
  tags = var.tags
}

resource "azurerm_container_app_environment" "env" {
  for_each = var.container-app-environment

  name = "${var.env}-${var.group}-${var.project}-${each.key}-cae"
  location = var.location
  resource_group_name = var.resource_groups[each.value.resource_group].name

  infrastructure_subnet_id = var.subnets[each.value.subnet].id
  internal_load_balancer_enabled = true

  identity {
    type = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.environment[each.key].id ]
  }

  dynamic "workload_profile" {
    for_each = each.value.workload_profiles

    content {
      name = workload_profile.key
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count = workload_profile.value.minimum_count
      maximum_count = workload_profile.value.maximum_count
    }
  }

  tags = var.tags
  #logs_destination = "azure-monitor"
}