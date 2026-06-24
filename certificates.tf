resource "azurerm_role_assignment" "cae-certificate-reader" {
  for_each = {
    for key, value in azurerm_user_assigned_identity.environment:
    key => value
    if var.keyvault_id != null
  }

  role_definition_name = "Key Vault Certificate User"
  scope = var.keyvault_id
  principal_id = each.value.principal_id
}

locals {
  container-app-certs = {
    for key, value in var.container-app-environment:
      key => try(value.certificate_names, [])
      
  }
}

# This will be a distinct set of all the certificate names across all container app environments in the keyvault
data "azurerm_key_vault_certificate" "lz-cert" {
  for_each = toset(
    flatten(values(local.container-app-certs))
  )

  name = each.key
  key_vault_id = var.keyvault_id
}

# Have to use azapi provider because importing certificate from key vault 
# is not (yet) supported by the azurerm provider
resource "azapi_resource" "cae-certificate" {
  depends_on = [ azurerm_role_assignment.cae-certificate-reader ]

  for_each = merge([
    for key, certs in local.container-app-certs:
    {
      for cert in certs:
        "${key} ${cert}" => {
          name = cert
          resource_id = azurerm_container_app_environment.env[key].id
          keyVaultUrl = data.azurerm_key_vault_certificate.lz-cert[cert].versionless_secret_id
          identity = azurerm_user_assigned_identity.environment[key].id
          location = azurerm_container_app_environment.env[key].location
        }
    }
  ]...)

  type = "Microsoft.App/managedEnvironments/certificates@2025-02-02-preview"
  parent_id = each.value.resource_id
  name = each.value.name
  location = each.value.location
  tags = var.tags

  body = {
    properties = {
      certificateKeyVaultProperties = {
        identity = each.value.identity
        keyVaultUrl = each.value.keyVaultUrl
      }
      certificateType = "ServerSSLCertificate"
    }
  }

  lifecycle {
    ignore_changes = [ body ]
  }  
}
