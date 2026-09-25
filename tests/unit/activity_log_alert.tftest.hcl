mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

run "creates_activity_log_alert" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg",
    ]
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/activityLogAlerts@2020-10-01"
    error_message = "The module must use the Activity Log Alert AzAPI resource type."
  }

  assert {
    condition     = azapi_resource.this.location == "global"
    error_message = "Activity Log Alerts must default to the global location."
  }
}

run "serializes_action_groups" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg",
    ]
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
    action_groups = [{
      action_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/actionGroups/activity-log-alert-action-group"
      webhook_properties = {
        severity = "high"
      }
    }]
  }

  assert {
    condition     = azapi_resource.this.body.properties.actions.actionGroups[0].actionGroupId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/actionGroups/activity-log-alert-action-group"
    error_message = "Action group IDs must be passed to the ARM body."
  }
}

run "rejects_invalid_parent_id" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "invalid"
    scopes    = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
  }

  expect_failures = [var.parent_id]
}

run "creates_optional_interfaces" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes    = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
    lock = {
      kind = "CanNotDelete"
    }
    role_assignments = {
      reader = {
        principal_id               = "00000000-0000-0000-0000-000000000000"
        role_definition_id_or_name = "Reader"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.lock) == 1
    error_message = "The lock interface must create an AzAPI lock."
  }

  assert {
    condition     = length(azapi_resource.role_assignments) == 1
    error_message = "The role assignment interface must create an AzAPI role assignment."
  }
}
