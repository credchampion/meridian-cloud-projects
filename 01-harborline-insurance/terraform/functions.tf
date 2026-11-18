resource "azurerm_storage_table" "claimlog" {
  name               = "claimlog"
  storage_account_id = azurerm_storage_account.claims.id
}

resource "azurerm_storage_account" "func" {
  name                            = "stfuncharborline${var.env}01"
  resource_group_name             = azurerm_resource_group.claims.name
  location                        = azurerm_resource_group.claims.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "func_deploy" {
  name                  = "app-package"
  storage_account_id    = azurerm_storage_account.func.id
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-harborline-claims-${var.env}"
  resource_group_name = azurerm_resource_group.claims.name
  location            = azurerm_resource_group.claims.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "func" {
  name                = "appi-harborline-claims-${var.env}"
  resource_group_name = azurerm_resource_group.claims.name
  location            = azurerm_resource_group.claims.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "other"
  tags                = local.tags
}

resource "azurerm_service_plan" "func" {
  name                = "asp-harborline-claims-${var.env}"
  resource_group_name = azurerm_resource_group.claims.name
  location            = azurerm_resource_group.claims.location
  sku_name            = "FC1"
  os_type             = "Linux"
  tags                = local.tags
}

resource "azurerm_function_app_flex_consumption" "claims" {
  name                        = "func-harborline-claims-${var.env}-01"
  resource_group_name         = azurerm_resource_group.claims.name
  location                    = azurerm_resource_group.claims.location
  service_plan_id             = azurerm_service_plan.func.id
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.func.primary_blob_endpoint}${azurerm_storage_container.func_deploy.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.func.primary_access_key
  runtime_name                = "python"
  runtime_version             = "3.11"
  maximum_instance_count      = 40
  instance_memory_in_mb       = 2048
  https_only                  = true

  site_config {
    application_insights_connection_string = azurerm_application_insights.func.connection_string
  }

  app_settings = {
    ClaimsStorage = azurerm_storage_account.claims.primary_connection_string
  }

  tags = local.tags
}
