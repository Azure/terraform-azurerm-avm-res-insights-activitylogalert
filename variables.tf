variable "name" {
  type        = string
  nullable    = false
  description = "The name of the Activity Log Alert."
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The fully-qualified ARM resource ID of the existing resource group in which the Activity Log Alert is deployed."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }
}

variable "condition" {
  type = object({
    all_of = list(object({
      field        = optional(string, null)
      equals       = optional(string, null)
      contains_any = optional(list(string), [])
      any_of = optional(list(object({
        field        = string
        equals       = optional(string, null)
        contains_any = optional(list(string), [])
      })), [])
    }))
  })
  nullable    = false
  description = <<DESCRIPTION
The conditions that activate the Activity Log Alert. Each entry in `all_of` is
either a leaf condition or an `any_of` group. A leaf condition requires `field`
and exactly one of `equals` or `contains_any`. An `any_of` group contains one
or more leaf conditions with the same requirements.
DESCRIPTION

  validation {
    condition = length(var.condition.all_of) > 0 && alltrue([
      for condition in var.condition.all_of :
      length(condition.any_of) > 0 ? (
        condition.field == null &&
        condition.equals == null &&
        length(condition.contains_any) == 0 &&
        alltrue([
          for any_of_condition in condition.any_of :
          (any_of_condition.equals != null) != (length(any_of_condition.contains_any) > 0)
        ])
      ) : (
        condition.field != null &&
        ((condition.equals != null) != (length(condition.contains_any) > 0))
      )
    ])
    error_message = "Each condition must be a leaf with `field` and exactly one operator, or a non-empty `any_of` group whose leaves each have exactly one operator."
  }
}

variable "scopes" {
  type        = list(string)
  nullable    = false
  description = "The resource IDs used as prefixes for Activity Log events evaluated by this alert. Resource IDs may be subscription, resource group, or resource scopes."

  validation {
    condition     = length(var.scopes) > 0
    error_message = "`scopes` must contain at least one resource ID."
  }
}

variable "action_groups" {
  type = list(object({
    action_group_id    = string
    webhook_properties = optional(map(string), null)
  }))
  default     = []
  nullable    = false
  description = "The action groups invoked when the alert activates, with optional webhook properties."

  validation {
    condition = alltrue([
      for action_group in var.action_groups :
      can(provider::azapi::parse_resource_id("Microsoft.Insights/actionGroups", action_group.action_group_id))
    ])
    error_message = "Each `action_group_id` must be a valid Action Group resource ID."
  }
}

variable "description" {
  type        = string
  default     = null
  description = "An optional description of the Activity Log Alert."
}

variable "enabled" {
  type        = bool
  default     = true
  nullable    = false
  description = "Whether the Activity Log Alert is enabled."
}

variable "location" {
  type        = string
  default     = "global"
  nullable    = false
  description = "The Azure location of the Activity Log Alert. Supported values are `global`, `westeurope`, and `northeurope`."

  validation {
    condition     = contains(["global", "westeurope", "northeurope"], lower(var.location))
    error_message = "`location` must be one of `global`, `westeurope`, or `northeurope`."
  }
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this Activity Log Alert.

- `kind` - The type of lock: `CanNotDelete` or `ReadOnly`.
- `name` - The optional lock name.
- `notes` - Optional lock notes.
DESCRIPTION

  validation {
    condition     = var.lock == null || contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "Lock kind must be either `CanNotDelete` or `ReadOnly`."
  }
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  nullable    = false
  description = "A map of role assignments to create on the Activity Log Alert. The map key is arbitrary to support unknown values at plan time."

  validation {
    condition = alltrue([
      for role_assignment in values(var.role_assignments) :
      role_assignment.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", role_assignment.delegated_managed_identity_resource_id))
    ])
    error_message = "Each delegated managed identity resource ID must be a valid user-assigned managed identity resource ID, or null."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to the Activity Log Alert."
}

variable "resource_types" {
  type = object({
    insights_activity_log_alerts   = optional(string, "Microsoft.Insights/activityLogAlerts@2020-10-01")
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `insights_activity_log_alerts` - The Activity Log Alert resource type.
- `authorization_locks` - The management lock resource type.
- `authorization_role_assignments` - The role assignment resource type.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to every AzAPI resource managed by the module. Defaults to `null`."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to every AzAPI resource managed by the module. Defaults to provider values."
}

variable "ignore_body_changes" {
  type = object({
    insights_activity_log_alerts   = optional(list(string), [])
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Body-relative dot-notation paths ignored by the AzAPI provider for each
resource. Ignored configuration is not sent to Azure until the path is removed,
and changes take effect only after apply.

- `insights_activity_log_alerts` - Paths ignored on the Activity Log Alert.
- `authorization_locks` - Paths ignored on management locks.
- `authorization_role_assignments` - Paths ignored on role assignments.
DESCRIPTION
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  nullable    = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
