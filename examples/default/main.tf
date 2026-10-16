data "azapi_client_config" "this" {}

resource "terraform_data" "name" {}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-activitylogalert-${substr(sha256(terraform_data.name.id), 0, 12)}"
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

module "this" {
  source    = "../../"
  providers = { modtm = modtm }

  condition = {
    all_of = [{
      field  = "category"
      equals = "Administrative"
    }]
  }
  location            = var.location
  name                = "ala-${substr(sha256(terraform_data.name.id), 0, 12)}"
  parent_id           = azapi_resource.resource_group.id
  scopes              = [azapi_resource.resource_group.id]
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.insights_activity_log_alerts
  resource_types      = var.resource_types.insights_activity_log_alerts
  retry               = var.retry
  tags                = var.tags
  timeouts            = var.timeouts
}
