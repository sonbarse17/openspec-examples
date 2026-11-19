mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { tenant_id = "11111111-1111-1111-1111-111111111111" }
  }
}

run "no_public_access_anywhere" {
  command = plan

  assert {
    condition     = module.app.public_network_access_enabled == false
    error_message = "App Service must have public access disabled"
  }
  assert {
    condition     = module.database.public_network_access_enabled == false
    error_message = "PostgreSQL must have public access disabled"
  }
  assert {
    condition     = module.keyvault.public_network_access_enabled == false
    error_message = "Key Vault must have public access disabled"
  }
  assert {
    condition     = module.gateway.private_only
    error_message = "Application Gateway must be internal only"
  }
}

run "prod_resilience" {
  command = plan

  assert {
    condition     = var.environment != "prod" || (module.database.high_availability_enabled && module.database.geo_redundant_backup)
    error_message = "Prod DB needs HA and geo-redundant backups"
  }
  assert {
    condition     = var.environment == "dev" || module.gateway.waf_mode == "Prevention"
    error_message = "UAT/Prod WAF must be in Prevention mode"
  }
}

run "overlapping_plan_is_rejected" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    name                 = "t"
    location             = "centralindia"
    resource_group_name  = "rg"
    environment          = "dev"
    address_plan         = { dev = "10.10.0.0/16", uat = "10.10.0.0/16" }
    allowed_client_cidrs = ["10.0.0.0/8"]
    tags                 = {}
  }
  expect_failures = [azurerm_virtual_network.this]
}

run "missing_required_tags_rejected" {
  command = plan
  variables {
    tags = { owner = "t" }
  }
  expect_failures = [var.tags]
}

run "network_default_deny_inbound" {
  command = plan
  module {
    source = "./modules/network"
  }
  variables {
    name                 = "t"
    location             = "centralindia"
    resource_group_name  = "rg"
    environment          = "dev"
    address_plan         = { dev = "10.10.0.0/16", uat = "10.20.0.0/16" }
    allowed_client_cidrs = ["10.0.0.0/8"]
    tags                 = {}
  }
  assert {
    condition = alltrue([for n in [azurerm_network_security_group.agw, azurerm_network_security_group.app, azurerm_network_security_group.pe] :
    anytrue([for r in n.security_rule : r.direction == "Inbound" && r.access == "Deny" && r.source_address_prefix == "Internet"])])
    error_message = "Every subnet NSG must explicitly deny inbound Internet traffic"
  }
}

run "identity_is_least_privilege" {
  command = plan
  module {
    source = "./modules/identity"
  }
  variables {
    name                = "t"
    location            = "centralindia"
    resource_group_name = "rg"
    key_vault_id        = "/subscriptions/0/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
    tags                = {}
  }
  assert {
    condition     = azurerm_role_assignment.app_secrets.role_definition_name == "Key Vault Secrets User" && azurerm_role_assignment.gateway_secrets.role_definition_name == "Key Vault Secrets User"
    error_message = "Workload identities may only read secrets"
  }
}

run "keyvault_hardening" {
  command = plan
  module {
    source = "./modules/keyvault"
  }
  variables {
    name                = "kv-t"
    location            = "centralindia"
    resource_group_name = "rg"
    tenant_id           = "11111111-1111-1111-1111-111111111111"
    pe_subnet_id        = "/subscriptions/0/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/v/subnets/s"
    dns_zone_id         = "/subscriptions/0/resourceGroups/rg/providers/Microsoft.Network/privateDnsZones/z"
    enable_lock         = false
    tags                = {}
  }
  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled && azurerm_key_vault.this.purge_protection_enabled && !azurerm_key_vault.this.public_network_access_enabled
    error_message = "Key Vault must be RBAC-only, purge-protected and private"
  }
}
