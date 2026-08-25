variable "env" {
  description = "Environment prefix used in the generated resource names"
  type        = string
  default     = "livetest"
}

variable "group" {
  description = "Group value used in the generated resource names"
  type        = string
  default     = "livetest"
}

variable "project" {
  description = "Project value used in the generated resource names"
  type        = string
  default     = "cae"
}

variable "location" {
  description = "Location for the throwaway live-test resource group"
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  description = "Tags applied to the resources created by this harness"
  type        = map(string)
  default = {
    purpose = "module-live-test"
  }
}

variable "pr_number" {
  description = <<-EOT
    Suffix applied to test_dependencies.tf resource names so concurrently
    open PRs against this module never collide on the same sandbox
    subscription. CI sources this from `TF_VAR_pr_number`
    (`github.event.number`); manual runs can leave the default or pass
    their own value.
  EOT
  type        = string
  default     = "manual"
}

variable "container-app-environment" {
  description = "Container app environment configuration objects, passed straight through to the module under test"
  type        = any
}

variable "container-app" {
  description = "Container app configuration objects, passed straight through to the module under test"
  type        = any
}
