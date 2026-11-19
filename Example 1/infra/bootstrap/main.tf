# One-time bootstrap, run ONCE PER ENVIRONMENT by a human with Owner rights (local state;
# use a separate working copy/workspace per env): state storage + keyless (OIDC) deploy identity.
#   terraform apply -var environment=dev -var subscription_id=<sub> ...
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

variable "project" { type = string }
variable "location" { type = string }
variable "github_repo" {
  type        = string
  description = "owner/repo allowed to deploy via OIDC"
}
variable "state_allowed_ips" {
  type        = list(string)
  default     = []
  description = "Public IPs (e.g. self-hosted runner egress) allowed to reach state storage."
}
variable "environment" { type = string }
variable "subscription_id" { type = string }

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "state" {
  name     = "rg-tfstate-${var.environment}"
  location = var.location
}

resource "azurerm_storage_account" "state" {
  name                            = "sttfstate${var.project}${var.environment}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false # Entra ID auth only
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
  }
  network_rules {
    default_action = "Deny"
    ip_rules       = var.state_allowed_ips
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

# Deploy identity per environment
resource "azuread_application" "deploy" {
  display_name = "sp-${var.project}-deploy-${var.environment}"
}

resource "azuread_service_principal" "deploy" {
  client_id = azuread_application.deploy.client_id
}

# GitHub Environment "<env>" (Prod has required reviewers = approval gate)
resource "azuread_application_federated_identity_credential" "gh" {
  application_id = azuread_application.deploy.id
  display_name   = "github-${var.environment}"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:environment:${var.environment}"
  audiences      = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.deploy.object_id
}

# Needed because the stack creates role assignments (Key Vault Secrets User).
resource "azurerm_role_assignment" "rbac_admin" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.deploy.object_id
}

resource "azurerm_role_assignment" "state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.deploy.object_id
}

output "deploy_client_ids" {
  value = azuread_application.deploy.client_id
}
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
