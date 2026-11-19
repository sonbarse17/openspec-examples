variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "workspace_id" { type = string }
variable "action_group_id" { type = string }
variable "severity" { type = number }
variable "app_id" { type = string }
variable "gateway_id" { type = string }
variable "database_id" { type = string }
variable "key_vault_id" { type = string }
variable "tags" { type = map(string) }

# --- Diagnostic settings: logs + metrics of every resource go to the workspace.
locals {
  diag_targets = {
    app      = var.app_id
    gateway  = var.gateway_id
    database = var.database_id
    vault    = var.key_vault_id
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                   = local.diag_targets
  name                       = "to-law"
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  enabled_log {
    category_group = "allLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

# --- Alerts
locals {
  alerts = {
    app-5xx = {
      scope = var.app_id, ns = "Microsoft.Web/sites", metric = "Http5xx",
      agg   = "Total", op = "GreaterThan", threshold = 10, dims = []
    }
    gateway-unhealthy = {
      scope = var.gateway_id, ns = "Microsoft.Network/applicationGateways", metric = "UnhealthyHostCount",
      agg   = "Average", op = "GreaterThan", threshold = 0, dims = []
    }
    db-cpu = {
      scope = var.database_id, ns = "Microsoft.DBforPostgreSQL/flexibleServers", metric = "cpu_percent",
      agg   = "Average", op = "GreaterThan", threshold = 80, dims = []
    }
    db-storage = {
      scope = var.database_id, ns = "Microsoft.DBforPostgreSQL/flexibleServers", metric = "storage_percent",
      agg   = "Average", op = "GreaterThan", threshold = 85, dims = []
    }
    db-failed-connections = {
      scope = var.database_id, ns = "Microsoft.DBforPostgreSQL/flexibleServers", metric = "connections_failed",
      agg   = "Total", op = "GreaterThan", threshold = 5, dims = []
    }
    vault-access-denied = {
      scope = var.key_vault_id, ns = "Microsoft.KeyVault/vaults", metric = "ServiceApiResult",
      agg   = "Total", op = "GreaterThan", threshold = 0,
      dims  = [{ name = "StatusCode", values = ["401", "403"] }]
    }
  }
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each            = local.alerts
  name                = "alert-${each.key}-${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [each.value.scope]
  severity            = var.severity
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = each.value.ns
    metric_name      = each.value.metric
    aggregation      = each.value.agg
    operator         = each.value.op
    threshold        = each.value.threshold

    dynamic "dimension" {
      for_each = each.value.dims
      content {
        name     = dimension.value.name
        operator = "Include"
        values   = dimension.value.values
      }
    }
  }
  action {
    action_group_id = var.action_group_id
  }
}
