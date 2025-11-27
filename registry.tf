# auto created registry if none specified
module "containerRegistry" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-container-registry.git?ref=v1.0.1"

  for_each = {
    for key, value in var.container-app-environment :
    key => value
    if try(value.registry_id, null) == null
  }

  userDefinedString = "${each.key}cae"
  env = var.env
  group = var.group
  project = var.project
  location = var.location
  resource_groups = var.resource_groups
  container_registry = {
    resource_group = var.container-app-environment[each.key].resource_group
    user_identity_enabled = true
    admin_enabled = false
    public_network_access_enabled = false
    data_endpoint_enabled = true

    # identity = {
    #   type = "SystemAssigned" # Example identity type
    #   identity_ids = [] # Example identity IDs
    # }

    private_endpoint = {
      registry = {
        resource_group    = "Project"
        subnet            = "RZ"
        subresource_names = ["registry"]
      }
    }
  }
  subnets = var.subnets
  private_dns_zone_ids = {}
  tags = var.tags
}

data "azurerm_container_registry" "existing" {
  for_each = {
    for key, value in var.container-app-environment :
    key => {
      resource_group_name = split("/resourceGroups/", split("/providers/", value.registry_id)[0])[1]
      name = split("/providers/Microsoft.ContainerRegistry/registries/", value.registry_id)[1]
    }
    if try(value.registry_id, null) != null
  }

  name = each.value.name
  resource_group_name = each.value.resource_group_name
}