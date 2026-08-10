# auto created registry if none specified
module "containerRegistry" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-container-registry.git?ref=v1.1.0"

  for_each = {
    for key, value in var.container-app-environment :
    key => value
    if try(value.registry_id, null) == null
  }

  userDefinedString = "${each.key}cae"
  env               = var.env
  group             = var.group
  project           = var.project
  location          = var.location
  resource_groups   = var.resource_groups
  container_registry = {
    resource_group                = var.container-app-environment[each.key].resource_group
    user_identity_enabled         = true
    admin_enabled                 = try(each.value.admin_enabled, false)
    public_network_access_enabled = false
    data_endpoint_enabled         = true

    # identity = {
    #   type = "SystemAssigned" # Example identity type
    #   identity_ids = [] # Example identity IDs
    # }

    private_endpoint = {
      registry = {
        resource_group    = var.container-app-environment[each.key].resource_group
        subnet            = try(var.container-app-environment[each.key].registry_private_endpoint_subnet, "RZ")
        subresource_names = ["registry"]
      }
    }
  }
  subnets              = var.subnets
  private_dns_zone_ids = {}
  tags                 = var.tags
}

data "azapi_resource" "existing_registry" {
  for_each = {
    for key, value in var.container-app-environment :
    key => value
    if try(value.registry_id, null) != null
  }

  type        = "Microsoft.ContainerRegistry/registries@2026-03-01-preview"
  resource_id = each.value.registry_id

  response_export_values = {
    login_server = "properties.loginServer"
  }
}
