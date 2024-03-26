resource "azurerm_resource_group" "fynetune_resource_group" {
  name     = "${var.fynetune_project}-rg"
  location = var.region
  tags     = local.common_tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/search_service
resource "azurerm_search_service" "fynetune_search_service" {
  name                          = "${var.fynetune_project}-ss"
  resource_group_name           = azurerm_resource_group.fynetune_resource_group.name
  location                      = var.region
  sku                           = var.search_service_sku
  hosting_mode                  = "default"
  partition_count               = 1
  replica_count                 = 1
  public_network_access_enabled = true
  local_authentication_enabled  = true
  authentication_failure_mode   = "http403"
  tags                          = local.common_tags
}

# Azure Cognitive Service
resource "azurerm_cognitive_account" "fynetune_cognitive_account" {
  name                          = "${var.fynetune_project}-ca"
  resource_group_name           = azurerm_resource_group.fynetune_resource_group.name
  location                      = var.region
  kind                          = "OpenAI"
  sku_name                      = var.cognitive_service_sku
  public_network_access_enabled = true
  custom_subdomain_name         = "${var.fynetune_project}-ca"
  tags                          = local.common_tags
}

resource "azurerm_storage_account" "fynetune_storage_account" {
  name                          = "${var.fynetune_project}sa"
  resource_group_name           = azurerm_resource_group.fynetune_resource_group.name
  location                      = var.region
  account_kind                  = var.storage_account_kind
  account_tier                  = var.storage_account_tier
  account_replication_type      = var.storage_account_replication_type
  shared_access_key_enabled     = true
  public_network_access_enabled = true

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server" "fynetune_postgresql_server" {
  name                = "${var.fynetune_project}-pg"
  resource_group_name = azurerm_resource_group.fynetune_resource_group.name
  location            = var.region

  sku_name                     = var.postgresql_server_sku
  version                      = var.postgres_version
  storage_mb                   = var.postgres_disk_size
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true
  zone                         = 1

  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "fynetune_postgresql_database" {
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.fynetune_postgresql_server.id
  collation = "en_US.utf8"
  charset   = "utf8"

  lifecycle {
    prevent_destroy = false
  }
}

# Allow only the Azure App Service to access the PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server_firewall_rule" "fynetune_postgresql_database_firewall_rule" {
  name             = "${azurerm_postgresql_flexible_server.fynetune_postgresql_server.name}-fw"
  server_id        = azurerm_postgresql_flexible_server.fynetune_postgresql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Azure App Service
resource "azurerm_service_plan" "fynetune_service_plan" {
  name                = "${var.fynetune_project}-sp"
  resource_group_name = azurerm_resource_group.fynetune_resource_group.name
  location            = var.region
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = local.common_tags
}

resource "azurerm_linux_web_app" "fynetune_app_service" {
  name                = local.fynetune_app_service_name
  resource_group_name = azurerm_resource_group.fynetune_resource_group.name
  location            = var.region
  service_plan_id     = azurerm_service_plan.fynetune_service_plan.id

  site_config {
    http2_enabled = true
    application_stack {
      docker_image_name   = "${var.docker_image_name}:${var.github_release_tag}"
      docker_registry_url = var.docker_registry_server
    }
  }

  logs {
    detailed_error_messages = false
    failed_request_tracing  = false

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  app_settings = merge(var.static_env_variables,
    {
      ADMIN_EMAIL                                 = var.admin_email
      ADMIN_PASSWORD                              = var.admin_password
      AZURE_AISEARCH_ENDPOINT                     = "https://${azurerm_search_service.fynetune_search_service.name}.search.windows.net"
      AZURE_AISEARCH_KEY                          = azurerm_search_service.fynetune_search_service.primary_key
      AZURE_OPENAI_URL                            = azurerm_cognitive_account.fynetune_cognitive_account.endpoint
      AZURE_OPENAI_API_KEY                        = azurerm_cognitive_account.fynetune_cognitive_account.primary_access_key
      AZURE_STORAGE_ACCOUNT                       = azurerm_storage_account.fynetune_storage_account.name
      AZURE_BLOB_CONNECTION_STRING                = azurerm_storage_account.fynetune_storage_account.primary_connection_string
      HOST_URL                                    = "https://${local.fynetune_app_service_name}.azurewebsites.net"
      KEY_MESSAGE                                 = "{\"message\":\"This is a secret message.\",\"expiry\":\"2024-05-24T06:13:41.045Z\"}"
      LICENSE_PUBLIC_KEY                          = var.license_public_key
      POSTGRES_HOST                               = azurerm_postgresql_flexible_server.fynetune_postgresql_server.fqdn
      POSTGRES_USER                               = var.postgres_admin_username
      POSTGRES_PASSWORD                           = var.postgres_admin_password
      POSTGRES_DATABASE                           = var.postgres_database_name
      POSTGRES_URL                                = "postgres://${var.postgres_admin_username}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.fynetune_postgresql_server.fqdn}:${var.postgres_port}/${var.postgres_database_name}?sslmode=require"
      POSTGRES_PRISMA_URL                         = "postgres://${var.postgres_admin_username}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.fynetune_postgresql_server.fqdn}:${var.postgres_port}/${var.postgres_database_name}?sslmode=require&pgbouncer=true&connect_timeout=15"
      POSTGRES_URL_NO_SSL                         = "postgres://${var.postgres_admin_username}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.fynetune_postgresql_server.fqdn}:${var.postgres_port}/${var.postgres_database_name}"
      POSTGRES_URL_NON_POOLING                    = "postgres://${var.postgres_admin_username}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.fynetune_postgresql_server.fqdn}:${var.postgres_port}/${var.postgres_database_name}?sslmode=require&pool_max_size=0"
      NEXT_PUBLIC_HOST                            = "https://${local.fynetune_app_service_name}.azurewebsites.net"
      NEXTAUTH_URL                                = "https://${local.fynetune_app_service_name}.azurewebsites.net"
      NEXTAUTH_URL_INTERNAL                       = "https://${local.fynetune_app_service_name}.azurewebsites.net"
      NEXT_PUBLIC_APP_DOMAIN                      = "${local.fynetune_app_service_name}.azurewebsites.net"
      NEXT_PUBLIC_AZURE_STORAGE_ACCOUNT           = azurerm_storage_account.fynetune_storage_account.name
      NEXT_PUBLIC_POSTGRES_HOST                   = azurerm_postgresql_flexible_server.fynetune_postgresql_server.fqdn
      NEXT_PUBLIC_AZURE_OPENAI_API_KEY            = azurerm_cognitive_account.fynetune_cognitive_account.primary_access_key
      NEXT_PUBLIC_AZURE_OPENAI_MODEL_API_ENDPOINT = "${azurerm_cognitive_account.fynetune_cognitive_account.endpoint}openai/deployments/"
      NEXT_PUBLIC_AZURE_AISEARCH_ENDPOINT         = "https://${azurerm_search_service.fynetune_search_service.name}.search.windows.net"
      MATOMO_URL                                  = var.matomo_app_url
      MATOMO_ID                                   = var.matomo_id
      OKTA_CLIENT_ID                              = var.okta_client_id
      OKTA_ISSUER                                 = var.okta_issuer
      OKTA_CLIENT_SECRET                          = var.okta_client_secret
      SPLUNK_ORG_TOKEN                            = var.splunk_org_token
      SPLUNK_REALM                                = var.splunk_realm
      SPLUNK_URL                                  = var.splunk_url
    }
  )

  tags = local.common_tags

  depends_on = [
    azurerm_postgresql_flexible_server_firewall_rule.fynetune_postgresql_database_firewall_rule
  ]
}
