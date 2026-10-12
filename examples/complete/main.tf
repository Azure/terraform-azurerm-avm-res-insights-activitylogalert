data "azapi_client_config" "this" {}

resource "terraform_data" "name" {}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-activitylogalert-complete-${substr(sha256(terraform_data.name.id), 0, 12)}"
  parent_id              = "/subscriptions/${data.azapi_client_config.this.subscription_id}"
  type                   = var.resource_types.resources_resource_groups
  body                   = {}
  ignore_body_changes    = length(var.ignore_body_changes.resources_resource_groups) > 0 ? var.ignore_body_changes.resources_resource_groups : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

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

resource "azapi_resource" "identity" {
  location               = var.location
  name                   = "id-activitylogalert-${substr(sha256(terraform_data.name.id), 0, 12)}"
  parent_id              = azapi_resource.resource_group.id
  type                   = var.resource_types.managedidentity_user_assigned_identities
  body                   = {}
  ignore_body_changes    = length(var.ignore_body_changes.managedidentity_user_assigned_identities) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities : null
  response_export_values = ["properties.principalId"]
  retry                  = var.retry
  tags                   = var.tags

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

module "this" {
  source = "../../"

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
  location            = var.location
  name                = "ala-resource-health-${substr(sha256(terraform_data.name.id), 0, 12)}"
  parent_id           = azapi_resource.resource_group.id
  scopes              = [azapi_resource.resource_group.id]
  description         = "Resource Health alert with a read-only lock and a scoped Reader assignment."
  enable_telemetry    = var.enable_telemetry
  enabled             = false
  ignore_body_changes = var.ignore_body_changes.insights_activity_log_alerts
  lock = {
    kind  = "ReadOnly"
    notes = "Protect the example alert from changes."
  }
  resource_types = var.resource_types.insights_activity_log_alerts
  retry          = var.retry
  role_assignments = {
    reader = {
      principal_id               = azapi_resource.identity.output.properties.principalId
      principal_type             = "ServicePrincipal"
      role_definition_id_or_name = "Reader"
    }
  }
  tags     = var.tags
  timeouts = var.timeouts
}
