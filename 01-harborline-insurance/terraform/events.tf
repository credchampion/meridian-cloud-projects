resource "azurerm_eventgrid_event_subscription" "claims_uploads" {
  name  = "evgs-claims-uploads-${var.env}"
  scope = azurerm_storage_account.claims.id

  azure_function_endpoint {
    function_id = "${azurerm_function_app_flex_consumption.claims.id}/functions/log_claim_upload"
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${azurerm_storage_container.uploads.name}/"
  }
}
