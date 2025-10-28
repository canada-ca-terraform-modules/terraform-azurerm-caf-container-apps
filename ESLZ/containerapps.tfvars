container-app-environment = {
  test = {
    resource_group = "Project"

    subnet = "APP"

    workload_profiles = {
      default = {
        workload_profile_type = "D4"
        maximum_count = 1
        minimum_count = 0
      }
    }

    cert_name = "some-certificate-in-the-keyvault-pfx"

    # Optional: ID to the LAW that should be used for container system and app logs
    # log_analytics_workspace_id = ""
  }
}

container-app = {
  test = {
    resource_group = "Project" # needs to be the same as the environment referenced above
    container-app-environment = "test" # this should be a key from above

    # Optional, the minimum number of instances of this app
    min_replicas = 0

    image = "nginx:latest" # this assumes the image is in the created registry
    cpu = 0.25
    memory = "0.5Gi"
    workload_profile_name = "default"
    
    ingress_target_port = 80 # the port that should be exposed on the container

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
      type = "UserAssigned" # or SystemAssigned, or SystemAssigned, UserAssigned
      identity_ids = []     # The UserAssigned identity ids
    }
  }
}