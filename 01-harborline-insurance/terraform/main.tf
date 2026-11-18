terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "env" {
  type    = string
  default = "stg"
}

variable "location" {
  type    = string
  default = "southcentralus"
}

locals {
  tags = {
    project    = "HARB-101"
    env        = var.env
    owner      = "adeoye"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "claims" {
  name     = "rg-harborline-claims-${var.env}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "claims" {
  name                            = "stharborlineclaims${var.env}01"
  resource_group_name             = azurerm_resource_group.claims.name
  location                        = azurerm_resource_group.claims.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "uploads" {
  name                  = "claims-uploads"
  storage_account_id    = azurerm_storage_account.claims.id
  container_access_type = "private"
}
