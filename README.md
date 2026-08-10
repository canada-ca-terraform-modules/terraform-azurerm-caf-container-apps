# terraform-azurerm-caf-container-apps

CAF module to deploy Azure Container App Environments and Container Apps, with
optional auto-created Azure Container Registry, Key Vault-backed custom domain
certificates, and user-assigned managed identities.

## New arguments (azurerm >= 5.0)

### container-app-environment — new top-level keys

| Key | Type | Description |
|---|---|---|
| `name` | string | Override the auto-generated environment name (default: `{env}-{group}-{project}-{key}-cae`) |
| `umi_name` | string | Override the auto-generated environment UMI name (default: `{env}-{group}-{project}-{key}-cae-umi`) |
| `umi_isolation_scope` | string | Isolation scope for the environment's UMI. Only possible value is `Regional` |
| `infrastructure_resource_group_name` | string | Name of the platform-managed infrastructure resource group |
| `zone_redundancy_enabled` | bool | Should the environment be created with Zone Redundancy enabled? |
| `mutual_tls_enabled` | bool | Should mutual TLS (mTLS) be enabled? |
| `public_network_access` | string | `Enabled` or `Disabled` |
| `logs_destination` | string | `log-analytics` or `azure-monitor` |
| `dapr_application_insights_connection_string` | string | Application Insights connection string used by Dapr |

### container-app — new top-level keys

| Key | Type | Description |
|---|---|---|
| `name` | string | Override the auto-generated app name (default: the map key) |
| `max_inactive_revisions` | number | The maximum number of inactive revisions allowed for this Container App |
| `max_replicas` | number | The maximum number of instances of this app |
| `secrets` | map(object) | Secrets exposed to the container via `value` / `key_vault_secret_id` / `identity` |
| `dapr` | object | Dapr integration (`app_id`, `app_port`, `app_protocol`) |
| `ingress_transport` | string | `auto`, `http`, `http2` or `tcp` |
| `ingress_allow_insecure_connections` | bool | Should ingress allow insecure (non-HTTPS) connections? |
| `ingress_exposed_port` | number | Exposed port for TCP ingress (only valid when `ingress_transport = "tcp"`) |
| `ip_security_restrictions` | map(object) | IP-filtering rules for the ingress |
| `cors` | object | CORS configuration for the ingress |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.12.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 5.0.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_containerRegistry"></a> [containerRegistry](#module\_containerRegistry) | github.com/canada-ca-terraform-modules/terraform-azurerm-caf-container-registry.git | v1.1.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.cae-certificate](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azurerm_container_app.apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_custom_domain.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_custom_domain) | resource |
| [azurerm_container_app_environment.env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_role_assignment.cae-certificate-reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azapi_resource.existing_registry](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |
| [azurerm_key_vault_certificate.lz-cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container-app"></a> [container-app](#input\_container-app) | n/a | `any` | `{}` | no |
| <a name="input_container-app-environment"></a> [container-app-environment](#input\_container-app-environment) | inputs | `any` | `{}` | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Env value for the name of the resource | `string` | n/a | yes |
| <a name="input_group"></a> [group](#input\_group) | (Required) Group value for the name of the resource | `string` | n/a | yes |
| <a name="input_keyvault_id"></a> [keyvault\_id](#input\_keyvault\_id) | The project key vault id from which certificates should be read | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure location for the resource | `string` | `"canadacentral"` | no |
| <a name="input_project"></a> [project](#input\_project) | (Required) Project value for the name of the resource | `string` | n/a | yes |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | Resouce group object containing a list of resource group in the target project | `any` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnet object containing a list of subnets in the target project | `any` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Maps of tags that will be applied to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apps"></a> [apps](#output\_apps) | n/a |
| <a name="output_environments"></a> [environments](#output\_environments) | n/a |
| <a name="output_registries"></a> [registries](#output\_registries) | n/a |
<!-- END_TF_DOCS -->
