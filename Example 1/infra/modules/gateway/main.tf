variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "private_ip" { type = string }
variable "identity_id" { type = string }
variable "tls_certificate_secret_id" { type = string }
variable "backend_fqdn" { type = string }
variable "health_check_path" { type = string }
variable "waf_mode" { type = string }
variable "min_capacity" { type = number }
variable "max_capacity" { type = number }
variable "zones" { type = list(string) }
variable "tags" { type = map(string) }

locals {
  fe_private = "fe-private"
  be_pool    = "pool-app"
  be_http    = "bes-https"
  probe      = "probe-app"
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "waf-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = var.waf_mode
  }
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

# NOTE: private-only frontend (no public IP) requires the
# Microsoft.Network/EnableApplicationGatewayNetworkIsolation feature on the subscription.
resource "azurerm_application_gateway" "this" {
  name                = "agw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  zones               = var.zones
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }
  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101" # TLS 1.2+
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  gateway_ip_configuration {
    name      = "gwip"
    subnet_id = var.subnet_id
  }
  frontend_ip_configuration {
    name                          = local.fe_private
    subnet_id                     = var.subnet_id
    private_ip_address            = var.private_ip
    private_ip_address_allocation = "Static"
  }
  frontend_port {
    name = "https"
    port = 443
  }
  frontend_port {
    name = "http"
    port = 80
  }

  ssl_certificate {
    name                = "tls"
    key_vault_secret_id = var.tls_certificate_secret_id
  }

  backend_address_pool {
    name  = local.be_pool
    fqdns = [var.backend_fqdn]
  }
  probe {
    name                                      = local.probe
    protocol                                  = "Https"
    path                                      = var.health_check_path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }
  backend_http_settings {
    name                                = local.be_http
    protocol                            = "Https"
    port                                = 443
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    probe_name                          = local.probe
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "listener-https"
    frontend_ip_configuration_name = local.fe_private
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "tls"
  }
  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = local.fe_private
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "listener-https"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                       = "rule-https"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "listener-https"
    backend_address_pool_name  = local.be_pool
    backend_http_settings_name = local.be_http
  }
  request_routing_rule {
    name                        = "rule-http-redirect"
    priority                    = 200
    rule_type                   = "Basic"
    http_listener_name          = "listener-http"
    redirect_configuration_name = "http-to-https"
  }
}

output "id" { value = azurerm_application_gateway.this.id }
output "private_only" { value = length(azurerm_application_gateway.this.frontend_ip_configuration) == 1 && var.private_ip != "" }
output "waf_mode" { value = azurerm_web_application_firewall_policy.this.policy_settings[0].mode }
