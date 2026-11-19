variable "subscription_id" {
  type = string
}

variable "use_oidc" {
  type    = bool
  default = false # true in CI (OIDC federation); false for local az login
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be dev, uat or prod."
  }
}

variable "project" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Must include owner and cost_center; environment is added automatically."
  validation {
    condition     = alltrue([for k in ["owner", "cost_center"] : contains(keys(var.tags), k)])
    error_message = "tags must include owner and cost_center."
  }
}

variable "allowed_client_cidrs" {
  type        = list(string)
  description = "Corporate/VPN ranges allowed to reach the internal gateway."
}

variable "tls_certificate_secret_id" {
  type        = string
  description = "Versionless Key Vault secret id of the PFX certificate used by the gateway (uploaded out-of-band)."
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "node_version" {
  type    = string
  default = "20-lts"
}

variable "secret_app_settings" {
  type        = map(string)
  default     = {}
  description = "App setting name => Key Vault secret URI; exposed as Key Vault references."
}

variable "db_admin" {
  type = object({
    object_id      = string
    name           = string
    principal_type = string # User | Group | ServicePrincipal
  })
  description = "Entra principal that administers PostgreSQL (creates the app DB principal)."
}

# Sizing / redundancy: the only things that differ between environments.
variable "app_sku" { type = string }
variable "app_instances" { type = number }
variable "zone_redundant" {
  type    = bool
  default = false
}
variable "db_sku" { type = string }
variable "db_storage_mb" {
  type    = number
  default = 32768
}
variable "db_backup_retention_days" { type = number }
variable "db_geo_redundant_backup" {
  type    = bool
  default = false
}
variable "db_high_availability" {
  type    = bool
  default = false
}
variable "waf_mode" {
  type = string
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "waf_mode must be Detection or Prevention."
  }
}
variable "gateway_min_capacity" { type = number }
variable "gateway_max_capacity" { type = number }
variable "log_retention_days" { type = number }
variable "alert_emails" { type = list(string) }
variable "alert_webhook_uris" {
  type        = list(string)
  default     = []
  description = "Paging endpoints (on-call). Prod only in practice."
}
variable "alert_severity" {
  type    = number
  default = 2
}
variable "enable_locks" {
  type    = bool
  default = false
}
