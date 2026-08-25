# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group or vnet:
# writing into a shared/L1-managed resource usually requires elevated,
# non-sandbox permissions. A dedicated throwaway RG + vnet here needs only
# Contributor on the sandbox subscription and can never collide with or
# affect any production resource.
#
# terraform-azurerm-caf-container-apps needs:
#   - resource_groups (keyed map) - var.resource_groups[<key>].name
#   - subnets (keyed map)         - var.subnets[<key>].id
#     - APP: delegated to Microsoft.App/environments, sized for a Dedicated
#       ("D4") workload profile (this fixture avoids "Consumption" - see
#       config/container-apps.tfvars for why).
#     - RZ: plain subnet for the auto-created container registry's private
#       endpoint (container-app-environment.registry_id is left unset, so
#       the module always provisions its own registry+private endpoint -
#       see registry.tf, which hardcodes public_network_access_enabled =
#       false with no override).

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module
  # from colliding on the same sandbox resource group.
  name     = "${var.env}-caf-container-apps-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag (ticket 13): lets the nightly orphan sweeper find this RG
  # by tag and match it back to a PR, independent of naming convention.
  tags = merge(var.tags, {
    "pr-number" = var.pr_number
  })
}

resource "azurerm_virtual_network" "live_test" {
  name                = "${var.env}-caf-container-apps-live-test-${var.pr_number}-vnet"
  address_space       = ["10.250.0.0/16"] # arbitrary, unpeered - collision-safe by construction
  location            = azurerm_resource_group.live_test.location
  resource_group_name = azurerm_resource_group.live_test.name
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  name                 = "APP"
  resource_group_name  = azurerm_resource_group.live_test.name
  virtual_network_name = azurerm_virtual_network.live_test.name
  address_prefixes     = ["10.250.0.0/23"]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "rz" {
  name                 = "RZ"
  resource_group_name  = azurerm_resource_group.live_test.name
  virtual_network_name = azurerm_virtual_network.live_test.name
  address_prefixes     = ["10.250.2.0/27"]
}

locals {
  # terraform-azurerm-caf-container-apps expects a purpose-keyed map, not a
  # flat object.
  resource_groups = {
    live_test = { name = azurerm_resource_group.live_test.name }
  }
  subnets = {
    APP = { id = azurerm_subnet.app.id }
    RZ  = { id = azurerm_subnet.rz.id }
  }
}
