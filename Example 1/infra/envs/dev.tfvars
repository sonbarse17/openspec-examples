environment     = "dev"
project         = "myapp"
location        = "centralindia"                         # TODO confirm region
subscription_id = "00000000-0000-0000-0000-000000000000" # TODO per-env subscription
tags = {
  owner       = "platform-team" # TODO
  cost_center = "CC-0000"       # TODO
}
allowed_client_cidrs      = ["10.0.0.0/8"]                                 # TODO corporate/VPN ranges
tls_certificate_secret_id = "https://TODO.vault.azure.net/secrets/agw-tls" # upload cert first, see README
db_admin = {
  object_id      = "00000000-0000-0000-0000-000000000000" # TODO Entra group
  name           = "db-admins"
  principal_type = "Group"
}
app_sku                  = "B1"
app_instances            = 1
db_sku                   = "B_Standard_B1ms"
db_backup_retention_days = 7
waf_mode                 = "Detection"
gateway_min_capacity     = 1
gateway_max_capacity     = 2
log_retention_days       = 30
alert_emails             = ["dev-team@example.com"] # TODO
alert_severity           = 3
