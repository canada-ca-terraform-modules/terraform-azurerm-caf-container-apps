container-app-environment = {
  test = {
    resource_group = "Project" # this can refer to a key in var.resource_groups or be a full resource ID

    subnet = "APP" # this can refer to a key in var.subnets or be a full resource ID

    workload_profiles = {
      default = {
        workload_profile_type = "D4"
        maximum_count         = 1
        minimum_count         = 0
      }
    }

    # Optional: name of certificate in Key Vault to be used by apps in this environment
    cert_name = "some-certificate-in-the-keyvault-pfx"

    # Optional: ID to the LAW that should be used for container system and app logs
    # log_analytics_workspace_id = ""

    # Optional: Information about an existing registry to reference. Otherwise a new registry will be created
    # registry_id = "/subscriptions/00000000-0000-0000-000
    # registry_pull_umi = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/umi-name"

    registry_private_endpoint_subnet = "RZ" # this can refer to a key in var.subnets or be a full resource ID, needs to be in the same VNet as the environment subnet

    # Optional: additional user-assigned identity IDs for the environment
    # additional_identity_ids = [
    #   "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/umi-name"
    # ]

    # Optional (azurerm >= 5.0): override the auto-generated environment name (default: {env}-{group}-{project}-{key}-cae)
    # name = ""

    # Optional (azurerm >= 5.0): override the auto-generated environment user-assigned identity name (default: {env}-{group}-{project}-{key}-cae-umi)
    # umi_name = ""

    # Optional (azurerm >= 5.0): isolation scope for the environment's user-assigned identity. Only possible value is "Regional"
    # umi_isolation_scope = "Regional"

    # Optional (azurerm >= 5.0): name of the platform-managed resource group hosting infrastructure resources
    # infrastructure_resource_group_name = ""

    # Optional (azurerm >= 5.0): should the environment be created with Zone Redundancy enabled?
    # zone_redundancy_enabled = false

    # Optional (azurerm >= 5.0): should mutual TLS (mTLS) be enabled?
    # mutual_tls_enabled = false

    # Optional (azurerm >= 5.0): public network access setting. Possible values are "Enabled" and "Disabled"
    # public_network_access = "Enabled"

    # Optional (azurerm >= 5.0): where application logs are saved. Possible values are "log-analytics" and "azure-monitor"
    # logs_destination = "log-analytics"

    # Optional (azurerm >= 5.0): Application Insights connection string used by Dapr
    # dapr_application_insights_connection_string = ""
  }
}

container-app = {
  test = {
    resource_group            = "Project" # needs to be the same as the environment referenced above
    container-app-environment = "test"    # this should be a key from above

    # Optional, the minimum number of instances of this app
    min_replicas = 0

    image                 = "nginx:latest" # this assumes the image is in the created/referenced registry
    cpu                   = 0.25
    memory                = "0.5Gi"
    workload_profile_name = "default"

    ingress_target_port      = 80   # the port that should be exposed on the container
    ingress_external_enabled = true # whether the application is available outside the environment

    # optional, environment variables
    env = {
      # key = "value"
    }

    # optional: this adds the custom domain so that it routes requests for these hosts to the application
    custom_domain_names = [
      "some.custom.domain.com",
    ]

    # optional, identity section
    identity = {
      type         = "UserAssigned" # or SystemAssigned, or SystemAssigned, UserAssigned
      identity_ids = []             # The UserAssigned identity ids
    }

    # Optional (azurerm >= 5.0): override the auto-generated app name (default: the map key, e.g. "test")
    # name = ""

    # Optional (azurerm >= 5.0): the maximum number of inactive revisions allowed for this Container App
    # max_inactive_revisions = 10

    # Optional (azurerm >= 5.0): the maximum number of instances of this app
    # max_replicas = 3

    # Optional (azurerm >= 5.0): secrets exposed to the container via secret_name / key_vault_secret_id / identity
    # secrets = {
    #   my-secret = {
    #     value               = "some-value"                 # OR
    #     key_vault_secret_id = "https://kv.vault.azure.net/secrets/my-secret"
    #     identity            = "System"                      # or a User Assigned Identity resource ID
    #   }
    # }

    # Optional (azurerm >= 5.0): Dapr integration
    # dapr = {
    #   app_id       = "my-app"
    #   app_port     = 80
    #   app_protocol = "http" # or "grpc"
    # }

    # Optional (azurerm >= 5.0): ingress transport protocol. Possible values are "auto", "http", "http2" and "tcp"
    # ingress_transport = "auto"

    # Optional (azurerm >= 5.0): should ingress allow insecure (non-HTTPS) connections?
    # ingress_allow_insecure_connections = false

    # Optional (azurerm >= 5.0): exposed port on the container for TCP ingress. Only valid when ingress_transport = "tcp"
    # ingress_exposed_port = 5000

    # Optional (azurerm >= 5.0): IP-filtering rules for the ingress
    # ip_security_restrictions = {
    #   allow-office = {
    #     action           = "Allow"
    #     ip_address_range = "1.2.3.4/32"
    #     description      = "Office network"
    #   }
    # }

    # Optional (azurerm >= 5.0): CORS configuration for the ingress
    # cors = {
    #   allowed_origins = ["https://example.com"]
    # }
  }
}
