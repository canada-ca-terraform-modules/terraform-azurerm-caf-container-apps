variable "container-app-environment" {
  type = any
  default = {}
}

variable "container-app" {
  type = any
  default = {}
}

module "containerApps" {
  source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-container-apps?ref=v0.1.0"

  container-app-environment = var.container-app-environment
  container-app = var.container-app
  keyvault_id = local.Project-kv.id

  env = var.env
  group = var.group
  project = var.project
  location = var.location
  resource_groups = local.resource_groups_all
  subnets = local.subnets
  tags = var.tags
}