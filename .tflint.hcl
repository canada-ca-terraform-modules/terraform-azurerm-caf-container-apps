config {
  call_module_type = "local"
  force            = false
}

plugin "azurerm" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

# Public variable names use the existing hyphenated CAF convention
# (container-app, container-app-environment) - renaming is a breaking change
# out of scope for a provider version upgrade.
rule "terraform_naming_convention" {
  enabled = false
}
