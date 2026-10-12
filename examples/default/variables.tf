variable "location" {
  type        = string
  default     = "westeurope"
  description = "The Azure region for the resource group and module telemetry."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    resources_resource_groups = optional(list(string), [])
    insights_activity_log_alerts = optional(object({
      insights_activity_log_alerts   = optional(list(string), [])
      authorization_locks            = optional(list(string), [])
      authorization_role_assignments = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths ignored after apply. Ignored configuration is not sent to Azure.

- `resources_resource_groups` - Resource group paths.
- `insights_activity_log_alerts` - Overrides passed to the Activity Log Alert module.
- `insights_activity_log_alerts.insights_activity_log_alerts` - Alert paths.
- `insights_activity_log_alerts.authorization_locks` - Lock paths.
- `insights_activity_log_alerts.authorization_role_assignments` - Role assignment paths.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    resources_resource_groups = optional(string, "Microsoft.Resources/resourceGroups@2024-03-01")
    insights_activity_log_alerts = optional(object({
      insights_activity_log_alerts   = optional(string)
      authorization_locks            = optional(string)
      authorization_role_assignments = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this example.

- `resources_resource_groups` - Resource group type and API version.
- `insights_activity_log_alerts` - Overrides passed to the Activity Log Alert module.
- `insights_activity_log_alerts.insights_activity_log_alerts` - Alert type and API version.
- `insights_activity_log_alerts.authorization_locks` - Lock type and API version.
- `insights_activity_log_alerts.authorization_role_assignments` - Role assignment type and API version.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "AzAPI retry error patterns, initial interval, and maximum interval in seconds."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "AzAPI create, read, update, and delete timeouts, expressed as Go duration strings."
}
