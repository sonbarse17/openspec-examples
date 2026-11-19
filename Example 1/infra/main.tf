data "azurerm_client_config" "current" {}

locals {
  name = "${var.project}-${var.environment}"
  # short stable suffix for globally-unique names (app, key vault, db)
  uniq = substr(md5("${var.subscription_id}${var.project}${var.environment}"), 0, 5)
  tags = merge(var.tags, { environment = var.environment })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source               = "./modules/network"
  name                 = local.name
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  environment          = var.environment
  address_plan         = jsondecode(file("${path.module}/address-plan.json"))
  allowed_client_cidrs = var.allowed_client_cidrs
  tags                 = local.tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  retention_days      = var.log_retention_days
  alert_emails        = var.alert_emails
  alert_webhook_uris  = var.alert_webhook_uris
  tags                = local.tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  name                = "kv-${substr(var.project, 0, 8)}-${var.environment}-${local.uniq}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  pe_subnet_id        = module.network.subnet_ids.pe
  dns_zone_id         = module.network.dns_zone_ids.vault
  enable_lock         = var.enable_locks
  tags                = local.tags
}

module "identity" {
  source              = "./modules/identity"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  key_vault_id        = module.keyvault.id
  tags                = local.tags
}

module "database" {
  source                = "./modules/database"
  name                  = "psql-${local.name}-${local.uniq}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.this.name
  tenant_id             = data.azurerm_client_config.current.tenant_id
  pe_subnet_id          = module.network.subnet_ids.pe
  dns_zone_id           = module.network.dns_zone_ids.postgres
  sku_name              = var.db_sku
  storage_mb            = var.db_storage_mb
  backup_retention_days = var.db_backup_retention_days
  geo_redundant_backup  = var.db_geo_redundant_backup
  high_availability     = var.db_high_availability
  admin                 = var.db_admin
  enable_lock           = var.enable_locks
  tags                  = local.tags
}

module "app" {
  source                         = "./modules/app"
  name                           = "app-${local.name}-${local.uniq}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  sku_name                       = var.app_sku
  instances                      = var.app_instances
  zone_redundant                 = var.zone_redundant
  node_version                   = var.node_version
  health_check_path              = var.health_check_path
  app_subnet_id                  = module.network.subnet_ids.app
  pe_subnet_id                   = module.network.subnet_ids.pe
  dns_zone_id                    = module.network.dns_zone_ids.sites
  identity_id                    = module.identity.app.id
  identity_client_id             = module.identity.app.client_id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  db_fqdn                        = module.database.fqdn
  db_user                        = module.identity.app.name # Entra principal created by scripts/create-db-principal.sh
  secret_app_settings            = var.secret_app_settings
  tags                           = local.tags
}

module "gateway" {
  source                    = "./modules/gateway"
  name                      = local.name
  location                  = var.location
  resource_group_name       = azurerm_resource_group.this.name
  subnet_id                 = module.network.subnet_ids.agw
  private_ip                = module.network.gateway_private_ip
  identity_id               = module.identity.gateway.id
  tls_certificate_secret_id = var.tls_certificate_secret_id
  backend_fqdn              = module.app.default_hostname
  health_check_path         = var.health_check_path
  waf_mode                  = var.waf_mode
  min_capacity              = var.gateway_min_capacity
  max_capacity              = var.gateway_max_capacity
  zones                     = var.zone_redundant ? ["1", "2", "3"] : []
  tags                      = local.tags

  depends_on = [module.identity] # RBAC on the vault must exist before the gateway reads the cert
}

module "alerts" {
  source              = "./modules/alerts"
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = module.monitoring.workspace_id
  action_group_id     = module.monitoring.action_group_id
  severity            = var.alert_severity
  app_id              = module.app.id
  gateway_id          = module.gateway.id
  database_id         = module.database.id
  key_vault_id        = module.keyvault.id
  tags                = local.tags
}

output "gateway_private_ip" { value = module.network.gateway_private_ip }
output "key_vault_uri" { value = module.keyvault.vault_uri }
output "app_name" { value = module.app.name }
output "database_fqdn" { value = module.database.fqdn }
