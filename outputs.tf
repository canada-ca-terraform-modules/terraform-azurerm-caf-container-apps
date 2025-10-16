output "environments" {
    value = { 
        for key, env in azurerm_container_app_environment.env:
            key => {
                object = env
                umi = azurerm_user_assigned_identity.environment[key]
            }
    }
}

output "apps" {
    value = {
        for key, app in azurerm_container_app.apps: 
            key => {
                object = app
                custom_domains = {
                    for domain_key, value in custom_azurerm_container_app_custom_domain.example:
                        split(" ", domain_key)[1] => value
                    if startswith(domain_key, key)
                }
            }
    }
}

output "registries" {
    value = { 
        for key, registry in module.container_registry: 
            key => {
                acr_pull_umi = registry.acr-pull-umi[0]
                object = registry.container-registry-object
            }
    }
}