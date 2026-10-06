terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_pet" "this" {
  length = 2
}

resource "azapi_resource" "resource_group" {
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
  name     = "rg-activitylogalert-${random_pet.this.id}"
  location = "westeurope"

  body = {}
}

module "activity_log_alert" {
  source = "../../"

  name      = "ala-${random_pet.this.id}"
  parent_id = azapi_resource.resource_group.id
  scopes    = [azapi_resource.resource_group.id]
  condition = {
    all_of = [{
      field  = "category"
      equals = "Administrative"
    }]
  }
}
