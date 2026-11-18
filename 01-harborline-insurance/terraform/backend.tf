terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateadeoye01"
    container_name       = "tfstate"
    key                  = "harborline/stg.tfstate"
  }
}
