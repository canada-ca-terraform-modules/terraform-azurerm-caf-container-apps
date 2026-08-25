# auto created registry if none specified
locals {
  # Extracted to a local (rather than inlined in the module call below) so its shape - notably
  # whether registry_private_dns_zone_id got wired into local_dns_zone - is directly assertable
  # from a tftest.hcl `assert` block, which can't reach into a called module's own resources.
  registry_private_endpoint = {
    for key, value in var.container-app-environment :
    key => merge(
      {
        resource_group    = value.resource_group
        subnet            = try(value.registry_private_endpoint_subnet, "RZ")
        subresource_names = ["registry"]
      },
      # Without a linked private DNS zone, the registry's private endpoint gets an IP but no
      # DNS record - the Container App Environment can never resolve the registry's hostname to
      # it, and every container app pull fails as if the pull identity itself lacked permission.
      # Opt-in only: callers using a registry reachable via public/existing DNS don't need this.
      try(value.registry_private_dns_zone_id, null) != null ? {
        local_dns_zone = value.registry_private_dns_zone_id
      } : {}
    )
  }
}

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
      registry = local.registry_private_endpoint[each.key]
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
