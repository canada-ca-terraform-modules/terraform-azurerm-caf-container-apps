terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }

  # Empty on purpose: the state file path is supplied at `terraform init`
  # time via `-backend-config="path=..."` (partial configuration), so the
  # target-branch checkout and the PR-branch checkout can point at the same
  # external state file without either owning its own local state.
  backend "local" {}
}

provider "azurerm" {
  storage_use_azuread             = true
  resource_provider_registrations = "legacy"
  features {}
}

provider "azapi" {}

module "container_apps" {
  # PR code and baseline code are two on-disk checkouts of this same repo,
  # not two resolved git refs - no pinned ?ref, no version toggle here.
  source = "../../"

  env             = var.env
  group           = var.group
  project         = var.project
  location        = var.location
  resource_groups = local.resource_groups # from test_dependencies.tf
  subnets         = local.subnets         # from test_dependencies.tf
  tags            = var.tags

  container-app-environment = var.container-app-environment
  container-app             = var.container-app
  keyvault_id               = null # out of scope for this harness - no certificate fixture
}
