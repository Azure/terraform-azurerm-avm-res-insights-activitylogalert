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
    action_groups = {
      primary = {
        action_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/actionGroups/activity-log-alert-action-group"
        webhook_properties = {
          severity = "high"
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.actions.actionGroups[0].actionGroupId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/actionGroups/activity-log-alert-action-group"
    error_message = "Action group IDs must be passed to the ARM body."
  }
}

run "serializes_description_and_tags" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes    = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
    description = "Alert on administrative events."
    tags = {
      environment = "test"
    }
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.description == "Alert on administrative events."
    error_message = "The description must be passed to the ARM body."
  }

  assert {
    condition     = azapi_resource.this.tags.environment == "test"
    error_message = "Tags must be passed to the Activity Log Alert."
  }
}

run "propagates_retry_and_timeouts" {
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
    retry = {
      interval_seconds = 10
    }
    timeouts = {
      create = "10m"
    }
  }

  assert {
    condition     = azapi_resource.this.retry.interval_seconds == 10
    error_message = "The retry configuration must be applied to the Activity Log Alert."
  }

  assert {
    condition     = azapi_resource.this.timeouts[0].create == "10m"
    error_message = "The timeout configuration must be applied to the Activity Log Alert."
  }
}

run "serializes_any_of_conditions" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes    = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
    condition = {
      all_of = [{
        any_of = [
          {
            field  = "category"
            equals = "Administrative"
          },
          {
            field        = "status"
            contains_any = ["Failed", "Succeeded"]
          },
        ]
      }]
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.condition.allOf[0].anyOf[1].containsAny[1] == "Succeeded"
    error_message = "Nested any-of conditions must be serialized to the ARM body."
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

run "rejects_unsupported_location" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    location  = "eastus"
    scopes    = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
  }

  expect_failures = [var.location]
}

run "rejects_empty_scopes" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes    = []
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
      }]
    }
  }

  expect_failures = [var.scopes]
}

run "rejects_invalid_action_group_id" {
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
    action_groups = {
      invalid = {
        action_group_id = "invalid"
      }
    }
  }

  expect_failures = [var.action_groups]
}

run "rejects_invalid_any_of_condition" {
  command = plan

  variables {
    name      = "activity-log-alert"
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
    scopes    = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
    condition = {
      all_of = [{
        any_of = [{
          field  = "category"
          equals = "Administrative"
          contains_any = [
            "ServiceHealth",
          ]
        }]
      }]
    }
  }

  expect_failures = [var.condition]
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
