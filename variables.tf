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
  description = <<DESCRIPTION
The conditions that activate the Activity Log Alert. Each entry in `all_of` is either a leaf condition or an `any_of` group. A leaf condition requires `field` and exactly one of `equals` or `contains_any`. An `any_of` group contains one or more leaf conditions with the same requirements.
DESCRIPTION
  nullable    = false

  validation {
    condition = length(var.condition.all_of) > 0 && alltrue([
      for condition in var.condition.all_of :
      length(condition.any_of) > 0 ? (
        condition.field == null &&
        condition.equals == null &&
        length(condition.contains_any) == 0 &&
        alltrue([
          for any_of_condition in condition.any_of :
          try(length(trimspace(any_of_condition.field)) > 0, false) &&
          (any_of_condition.equals != null) != (length(any_of_condition.contains_any) > 0)
        ])
        ) : (
        try(length(trimspace(condition.field)) > 0, false) &&
        ((condition.equals != null) != (length(condition.contains_any) > 0))
      )
    ])
    error_message = "Each condition must be a leaf with `field` and exactly one operator, or a non-empty `any_of` group whose leaves each have exactly one operator."
  }
}

variable "location" {
  type        = string
  description = "The Azure region used for module telemetry. Use `resource_location` to choose the Activity Log Alert's location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the Activity Log Alert."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The fully-qualified ARM resource ID of the existing resource group in which the Activity Log Alert is deployed."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }
}

variable "scopes" {
  type        = list(string)
  description = "The resource IDs used as prefixes for Activity Log events evaluated by this alert. Resource IDs may be subscription, resource group, or resource scopes."
  nullable    = false

  validation {
    condition     = length(var.scopes) > 0
    error_message = "`scopes` must contain at least one resource ID."
  }
}

variable "action_groups" {
  type = map(object({
    action_group_id    = string
    webhook_properties = optional(map(string), null)
  }))
  default     = {}
  description = "A map of action groups invoked when the alert activates, with optional webhook properties. The map key is arbitrary to support unknown values at plan time."
  nullable    = false

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

variable "enabled" {
  type        = bool
  default     = true
  description = "Whether the Activity Log Alert is enabled."
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    insights_activity_log_alerts   = optional(list(string), [])
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths ignored by the AzAPI provider for each resource, for example `properties.description`. Ignored configuration is not sent to Azure until the path is removed, and changes take effect only after apply.

Non-empty lists require Terraform 1.11 or later. Individual list items cannot be targeted; ignore the entire list property instead.

- `insights_activity_log_alerts` - Paths ignored on the Activity Log Alert.
- `authorization_locks` - Paths ignored on management locks.
- `authorization_role_assignments` - Paths ignored on role assignments.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
- `notes` - (Optional) Notes about the lock. This value maps to `Microsoft.Authorization/locks.properties.notes`.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "resource_location" {
  type        = string
  default     = "global"
  description = "The Azure location of the Activity Log Alert. The `2020-10-01` ARM API supports `global`, `westeurope`, and `northeurope`."
  nullable    = false

  validation {
    condition     = contains(["global", "westeurope", "northeurope"], lower(var.resource_location))
    error_message = "`resource_location` must be one of `global`, `westeurope`, or `northeurope`."
  }
}

variable "resource_types" {
  type = object({
    insights_activity_log_alerts   = optional(string, "Microsoft.Insights/activityLogAlerts@2020-10-01")
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `insights_activity_log_alerts` - The Activity Log Alert resource type.
- `authorization_locks` - The management lock resource type.
- `authorization_role_assignments` - The role assignment resource type.
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
  description = <<DESCRIPTION
Retry configuration applied to every AzAPI resource managed by the module. Defaults to `null` (no custom retry).

- `error_message_regex` - Error message patterns that trigger a retry.
- `interval_seconds` - Initial interval between retries in seconds.
- `max_interval_seconds` - Maximum interval between retries in seconds.
DESCRIPTION
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
  description = <<DESCRIPTION
A map of role assignments to create on the Activity Log Alert. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the role assignment. If not set, a random UUID will be generated. Changing this forces the creation of a new resource.
- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.role_assignments :
      v.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", v.delegated_managed_identity_resource_id))
    ])
    error_message = "Each `role_assignments[*].delegated_managed_identity_resource_id` must be a valid user-assigned managed identity resource ID, or null."
  }
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
  description = <<DESCRIPTION
Per-operation timeouts applied to every AzAPI resource managed by the module. Defaults to provider values. Each value is a Go duration string, for example `30m` or `1h`.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
