terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # exact version pinned by committed .terraform.lock.hcl
    }
  }

  # Per-environment state: terraform init -backend-config=envs/<env>.backend.hcl
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true
  use_oidc            = var.use_oidc
}
