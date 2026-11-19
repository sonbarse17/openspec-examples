variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "key_vault_id" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-app-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "gateway" {
  name                = "id-agw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Least privilege, scoped to the one vault: read-only secrets.
resource "azurerm_role_assignment" "app_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "gateway_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gateway.principal_id
}

output "app" {
  value = {
    id           = azurerm_user_assigned_identity.app.id
    principal_id = azurerm_user_assigned_identity.app.principal_id
    client_id    = azurerm_user_assigned_identity.app.client_id
    name         = azurerm_user_assigned_identity.app.name
  }
}
output "gateway" {
  value = {
    id           = azurerm_user_assigned_identity.gateway.id
    principal_id = azurerm_user_assigned_identity.gateway.principal_id
  }
}
