# Produces the AzAPI resource inputs for supported AVM lock and RBAC interfaces.
module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "~> 0.6"

  lock                             = var.lock
  lock_scope                       = azapi_resource.this.id
  role_assignments                 = var.role_assignments
  role_assignment_definition_scope = azapi_resource.this.id
}

resource "azapi_resource" "this" {
  type      = var.resource_types.insights_activity_log_alerts
  name      = var.name
  parent_id = var.parent_id
  location  = var.location
  tags      = var.tags

  body = {
    properties = merge({
      actions = {
        actionGroups = [
          for action_group in var.action_groups : merge(
            {
              actionGroupId = action_group.action_group_id
            },
            action_group.webhook_properties == null ? {} : {
              webhookProperties = action_group.webhook_properties
            }
          )
        ]
      }
      condition = {
        allOf = [
          for condition in var.condition.all_of : merge(
            length(condition.any_of) > 0 ? {
              anyOf = [
                for any_of_condition in condition.any_of : merge(
                  {
                    field = any_of_condition.field
                  },
                  any_of_condition.equals == null ? {} : { equals = any_of_condition.equals },
                  length(any_of_condition.contains_any) == 0 ? {} : { containsAny = any_of_condition.contains_any }
                )
              ]
            } : {
              field = condition.field
            },
            condition.equals == null ? {} : { equals = condition.equals },
            length(condition.contains_any) == 0 ? {} : { containsAny = condition.contains_any }
          )
        ]
      }
      enabled = var.enabled
      scopes  = var.scopes
      },
      var.description == null ? {} : { description = var.description }
    )
  }

  ignore_body_changes    = length(var.ignore_body_changes.insights_activity_log_alerts) > 0 ? var.ignore_body_changes.insights_activity_log_alerts : null
  response_export_values = []
  retry                  = var.retry
  create_headers         = local.avm_azapi_request_headers
  read_headers           = local.avm_azapi_request_headers
  update_headers         = local.avm_azapi_request_headers
  delete_headers         = local.avm_azapi_request_headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "lock" {
  count = var.lock == null ? 0 : 1

  type      = var.resource_types.authorization_locks
  name      = module.avm_interfaces.lock_azapi.name
  parent_id = module.avm_interfaces.lock_azapi.parent_id
  body      = module.avm_interfaces.lock_azapi.body

  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry
  create_headers         = local.avm_azapi_request_headers
  read_headers           = local.avm_azapi_request_headers
  update_headers         = local.avm_azapi_request_headers
  delete_headers         = local.avm_azapi_request_headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  type      = var.resource_types.authorization_role_assignments
  name      = each.value.name
  parent_id = each.value.parent_id
  body      = each.value.body

  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  response_export_values = []
  retry                  = var.retry
  create_headers         = local.avm_azapi_request_headers
  read_headers           = local.avm_azapi_request_headers
  update_headers         = local.avm_azapi_request_headers
  delete_headers         = local.avm_azapi_request_headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
