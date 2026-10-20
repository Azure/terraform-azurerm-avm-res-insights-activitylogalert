mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/activityLogAlerts/activity-log-alert"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000001"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          role_name = "Reader"
        }]
      }
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-1111-1111-111111111111"
    }
  }
}

mock_provider "terraform" {}

variables {
  location         = "westeurope"
  name             = "activity-log-alert"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg"
  scopes           = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
  enable_telemetry = false
  condition = {
    all_of = [{
      field  = "category"
      equals = "Administrative"
    }]
  }
}

run "creates_activity_log_alert" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/activityLogAlerts@2020-10-01"
    error_message = "The module must use the tested Activity Log Alert API."
  }

  assert {
    condition     = azapi_resource.this.location == "global" && azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.name == var.name
    error_message = "The alert must use the supplied name and parent, independently of the telemetry region."
  }

  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.resource_id != ""
    error_message = "The module must return the deployed alert resource ID."
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties) == jsonencode({
      actions = { actionGroups = [] }
      condition = {
        allOf = [{ field = "category", equals = "Administrative" }]
      }
      enabled = true
      scopes  = var.scopes
    })
    error_message = "Defaults must serialize without null operators or an absent description."
  }

  assert {
    condition     = length(azapi_resource.lock) == 0 && length(azapi_resource.role_assignments) == 0
    error_message = "Optional interfaces must not create resources by default."
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Opting out must disable telemetry."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "serializes_service_health_conditions" {
  command = apply

  variables {
    condition = {
      all_of = [
        { field = "category", equals = "ServiceHealth" },
        { field = "properties.incidentType", equals = "Incident" },
      ]
    }
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.condition) == jsonencode({
      allOf = [
        { field = "category", equals = "ServiceHealth" },
        { field = "properties.incidentType", equals = "Incident" },
      ]
    })
    error_message = "Service Health conditions must retain their field names and values."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "serializes_mixed_resource_health_conditions" {
  command = apply

  variables {
    condition = {
      all_of = [
        { field = "category", equals = "ResourceHealth" },
        {
          any_of = [
            { field = "properties.cause", equals = "PlatformInitiated" },
            { field = "properties.cause", equals = "UserInitiated" },
          ]
        },
        {
          any_of = [
            { field = "properties.currentHealthStatus", equals = "Degraded" },
            { field = "properties.currentHealthStatus", equals = "Unavailable" },
          ]
        },
      ]
    }
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.condition) == jsonencode({
      allOf = [
        { field = "category", equals = "ResourceHealth" },
        {
          anyOf = [
            { field = "properties.cause", equals = "PlatformInitiated" },
            { field = "properties.cause", equals = "UserInitiated" },
          ]
        },
        {
          anyOf = [
            { field = "properties.currentHealthStatus", equals = "Degraded" },
            { field = "properties.currentHealthStatus", equals = "Unavailable" },
          ]
        },
      ]
    })
    error_message = "Leaf conditions and multiple anyOf groups must coexist without null fields or type coercion."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "serializes_contains_any_conditions" {
  command = apply

  variables {
    condition = {
      all_of = [
        { field = "category", equals = "Administrative" },
        { field = "level", contains_any = ["Error", "Warning"] },
        {
          any_of = [
            { field = "status", equals = "Failed" },
            { field = "subStatus", contains_any = ["BadRequest", "Conflict"] },
          ]
        },
      ]
    }
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.condition) == jsonencode({
      allOf = [
        { field = "category", equals = "Administrative" },
        { field = "level", containsAny = ["Error", "Warning"] },
        {
          anyOf = [
            { field = "status", equals = "Failed" },
            { field = "subStatus", containsAny = ["BadRequest", "Conflict"] },
          ]
        },
      ]
    })
    error_message = "Both leaf and nested containsAny operators must serialize as arrays."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "serializes_action_groups" {
  command = apply

  variables {
    action_groups = {
      primary = {
        action_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/actionGroups/primary"
        webhook_properties = {
          severity = "high"
        }
      }
      secondary = {
        action_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/activity-log-alert-rg/providers/Microsoft.Insights/actionGroups/secondary"
      }
    }
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.actions.actionGroups) == jsonencode([
      {
        actionGroupId     = var.action_groups.primary.action_group_id
        webhookProperties = { severity = "high" }
      },
      { actionGroupId = var.action_groups.secondary.action_group_id },
    ])
    error_message = "Action groups must retain stable map ordering and omit unspecified webhook properties."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "serializes_optional_properties" {
  command = apply

  variables {
    description       = "Alert on administrative events."
    enabled           = false
    resource_location = "northeurope"
    tags              = { environment = "test" }
  }

  assert {
    condition     = azapi_resource.this.body.properties.description == var.description && !azapi_resource.this.body.properties.enabled
    error_message = "The description and disabled state must be passed to Azure."
  }

  assert {
    condition     = azapi_resource.this.location == "northeurope" && azapi_resource.this.tags.environment == "test"
    error_message = "Resource residency and tags must be configurable independently of telemetry."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "creates_optional_interfaces_and_controls" {
  command = apply

  variables {
    lock = {
      kind  = "CanNotDelete"
      notes = "Unit test lock."
    }
    role_assignments = {
      reader = {
        principal_id               = "00000000-0000-0000-0000-000000000002"
        role_definition_id_or_name = "Reader"
        principal_type             = "ServicePrincipal"
      }
    }
    resource_types = {
      insights_activity_log_alerts = "Microsoft.Insights/activityLogAlerts@2017-04-01"
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 10
      max_interval_seconds = 60
    }
    timeouts = {
      create = "10m"
      read   = "2m"
      update = "10m"
      delete = "5m"
    }
    ignore_body_changes = {
      insights_activity_log_alerts   = ["properties.description"]
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
    }
  }

  assert {
    condition     = azapi_resource.this.type == var.resource_types.insights_activity_log_alerts
    error_message = "The primary resource API version must honor the consumer override."
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete" && azapi_resource.lock[0].parent_id == output.resource_id
    error_message = "An unnamed lock must get a stable name and the alert resource scope."
  }

  assert {
    condition     = azapi_resource.lock[0].body.properties.level == "CanNotDelete" && azapi_resource.lock[0].body.properties.notes == "Unit test lock."
    error_message = "Lock properties must be retained."
  }

  assert {
    condition     = azapi_resource.role_assignments["reader"].parent_id == output.resource_id && azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    error_message = "Role names must resolve to IDs and assignments must target the alert."
  }

  assert {
    condition = alltrue([
      for resource in [azapi_resource.this, azapi_resource.lock[0], azapi_resource.role_assignments["reader"]] :
      resource.retry.interval_seconds == 10 &&
      resource.retry.max_interval_seconds == 60 &&
      resource.timeouts.create == "10m" &&
      resource.timeouts.read == "2m" &&
      resource.timeouts.update == "10m" &&
      resource.timeouts.delete == "5m"
    ])
    error_message = "All owned AzAPI resources must receive retry and operation timeouts."
  }

  assert {
    condition = alltrue([
      for resource in [azapi_resource.this, azapi_resource.lock[0], azapi_resource.role_assignments["reader"]] :
      alltrue([
        for headers in [resource.create_headers, resource.read_headers, resource.update_headers, resource.delete_headers] :
        !contains(keys(coalesce(headers, {})), "User-Agent")
      ])
    ])
    error_message = "Owned resources must not configure retired per-resource User-Agent telemetry."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "honors_explicit_interface_names" {
  command = apply

  variables {
    lock = {
      kind = "ReadOnly"
      name = "explicit-lock"
    }
    role_assignments = {
      reader = {
        name                       = "22222222-2222-2222-2222-222222222222"
        principal_id               = "00000000-0000-0000-0000-000000000002"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_type             = "ServicePrincipal"
      }
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "explicit-lock" && azapi_resource.role_assignments["reader"].name == "22222222-2222-2222-2222-222222222222"
    error_message = "Explicit lock and role assignment names must be honored."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "enables_telemetry" {
  command = apply

  variables {
    enable_telemetry = true
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && azapi_resource.telemetry[0].location == "westeurope"
    error_message = "Enabled telemetry must use the regional location, not the global resource location."
  }

  assert {
    condition = alltrue([
      for headers in [azapi_resource.this.create_headers, azapi_resource.this.read_headers, azapi_resource.this.update_headers, azapi_resource.this.delete_headers] :
      !contains(keys(coalesce(headers, {})), "User-Agent")
    ])
    error_message = "Deployment telemetry must not reintroduce custom User-Agent telemetry on the alert."
  }
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_unsupported_resource_location" {
  command = plan

  variables {
    resource_location = "eastus"
  }

  expect_failures = [var.resource_location]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_empty_scopes" {
  command = plan

  variables {
    scopes = []
  }

  expect_failures = [var.scopes]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_invalid_action_group_id" {
  command = plan

  variables {
    action_groups = {
      invalid = { action_group_id = "invalid" }
    }
  }

  expect_failures = [var.action_groups]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_empty_conditions" {
  command = plan

  variables {
    condition = { all_of = [] }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_leaf_without_field" {
  command = plan

  variables {
    condition = { all_of = [{ equals = "Administrative" }] }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_blank_field" {
  command = plan

  variables {
    condition = { all_of = [{ field = " ", equals = "Administrative" }] }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_leaf_without_operator" {
  command = plan

  variables {
    condition = { all_of = [{ field = "category" }] }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_leaf_with_both_operators" {
  command = plan

  variables {
    condition = {
      all_of = [{ field = "category", equals = "Administrative", contains_any = ["ServiceHealth"] }]
    }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_empty_any_of" {
  command = plan

  variables {
    condition = { all_of = [{ any_of = [] }] }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_group_with_leaf_properties" {
  command = plan

  variables {
    condition = {
      all_of = [{
        field  = "category"
        equals = "Administrative"
        any_of = [{ field = "status", equals = "Failed" }]
      }]
    }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_any_of_without_operator" {
  command = plan

  variables {
    condition = { all_of = [{ any_of = [{ field = "status" }] }] }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_any_of_with_both_operators" {
  command = plan

  variables {
    condition = {
      all_of = [{
        any_of = [{ field = "status", equals = "Failed", contains_any = ["Succeeded"] }]
      }]
    }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_null_any_of_field" {
  command = plan

  variables {
    condition = {
      all_of = [{ any_of = [{ field = null, equals = "Failed" }] }]
    }
  }

  expect_failures = [var.condition]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_invalid_lock" {
  command = plan

  variables {
    lock = { kind = "Invalid" }
  }

  expect_failures = [var.lock]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}

run "rejects_invalid_delegated_identity" {
  command = plan

  variables {
    role_assignments = {
      reader = {
        principal_id                           = "00000000-0000-0000-0000-000000000002"
        role_definition_id_or_name             = "Reader"
        delegated_managed_identity_resource_id = "invalid"
      }
    }
  }

  expect_failures = [var.role_assignments]
  providers = {
    azapi     = azapi
    random    = random
    terraform = terraform
  }
}
