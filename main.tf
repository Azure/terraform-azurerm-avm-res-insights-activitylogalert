module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                 = var.enable_telemetry
  lock                             = var.lock
  role_assignment_definition_scope = azapi_resource.this.id
  role_assignments                 = var.role_assignments
}

resource "azapi_resource" "this" {
  location  = var.resource_location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.insights_activity_log_alerts
  body = {
    properties = merge({
      actions = {
        actionGroups = [
          for action_group in values(var.action_groups) : merge(
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
        allOf = local.all_of_conditions
      }
      enabled = var.enabled
      scopes  = var.scopes
      },
      var.description == null ? {} : { description = var.description }
    )
  }
  create_headers         = local.avm_azapi_request_headers
  delete_headers         = local.avm_azapi_request_headers
  ignore_body_changes    = length(var.ignore_body_changes.insights_activity_log_alerts) > 0 ? var.ignore_body_changes.insights_activity_log_alerts : null
  read_headers           = local.avm_azapi_request_headers
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags
  update_headers         = local.avm_azapi_request_headers

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

  name                   = coalesce(module.avm_interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.authorization_locks
  body                   = module.avm_interfaces.lock_azapi.body
  create_headers         = local.avm_azapi_request_headers
  delete_headers         = local.avm_azapi_request_headers
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  read_headers           = local.avm_azapi_request_headers
  response_export_values = []
  retry                  = var.retry
  update_headers         = local.avm_azapi_request_headers

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [azapi_resource.role_assignments]
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name                = each.value.name
  parent_id           = azapi_resource.this.id
  type                = var.resource_types.authorization_role_assignments
  body                = each.value.body
  create_headers      = local.avm_azapi_request_headers
  delete_headers      = local.avm_azapi_request_headers
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  read_headers        = local.avm_azapi_request_headers
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  retry                  = var.retry
  update_headers         = local.avm_azapi_request_headers

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
