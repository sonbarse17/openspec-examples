variable "name" { type = string } # globally unique
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "sku_name" { type = string }
variable "instances" { type = number }
variable "zone_redundant" { type = bool }
variable "node_version" { type = string }
variable "health_check_path" { type = string }
variable "app_subnet_id" { type = string }
variable "pe_subnet_id" { type = string }
variable "dns_zone_id" { type = string }
variable "identity_id" { type = string }
variable "identity_client_id" { type = string }
variable "app_insights_connection_string" { type = string }
variable "db_fqdn" { type = string }
variable "db_user" { type = string }
variable "secret_app_settings" { type = map(string) }
variable "tags" { type = map(string) }

resource "azurerm_service_plan" "this" {
  name                   = "asp-${var.name}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  os_type                = "Linux"
  sku_name               = var.sku_name
  worker_count           = var.instances
  zone_balancing_enabled = var.zone_redundant
  tags                   = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                                           = var.name
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  public_network_access_enabled                  = false
  virtual_network_subnet_id                      = var.app_subnet_id
  key_vault_reference_identity_id                = var.identity_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  tags                                           = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  site_config {
    minimum_tls_version               = "1.2"
    ftps_state                        = "Disabled"
    vnet_route_all_enabled            = true
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = 10
    application_stack {
      node_version = var.node_version
    }
  }

  app_settings = merge(
    {
      APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
      DB_HOST                               = var.db_fqdn
      DB_USER                               = var.db_user
      AZURE_CLIENT_ID                       = var.identity_client_id # for DefaultAzureCredential
    },
    { for k, uri in var.secret_app_settings : k => "@Microsoft.KeyVault(SecretUri=${uri})" }
  )
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "app"
    private_connection_resource_id = azurerm_linux_web_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}

output "id" { value = azurerm_linux_web_app.this.id }
output "default_hostname" { value = azurerm_linux_web_app.this.default_hostname }
output "name" { value = azurerm_linux_web_app.this.name }
output "public_network_access_enabled" { value = azurerm_linux_web_app.this.public_network_access_enabled }
