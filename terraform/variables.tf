
variable "fynetune_project" {
  description = "Name of the project (should be unique)"
  validation {
    condition     = can(regex("^[a-z0-9]{5,16}$", var.fynetune_project))
    error_message = "The project name should have atleast 5 characters and should not contain special characters"
  }
}

variable "region" {
  description = "Location of the resources to be created"
  default     = "eastus"
}

variable "docker_image_name" {
  description = "Docker image to be deployed"
  default     = "fynetune/app"
}

variable "github_release_tag" {
  description = "Docker image tag"
  default     = "0.0.1"
}

variable "docker_registry_server" {
  description = "Docker registry server"
  default     = "https://fynetune.azurecr.io"
}

# Azure Search Service
variable "search_service_sku" {
  description = "The SKU of the Search Service"
  default     = "standard"
}

# Azure Cognitive Service
variable "cognitive_service_sku" {
  description = "The SKU of the Cognitive Service"
  default     = "S0"
}

variable "cognitive_service_sku_tier" {
  description = "The SKU tier of the Cognitive Service"
  default     = "Standard"
}

# Azure Storage Account
variable "storage_account_kind" {
  description = "The kind of the Storage Account"
  default     = "StorageV2"
}
variable "storage_account_tier" {
  description = "The tier of the Storage Account"
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "The replication type of the Storage Account"
  default     = "LRS"
}

# Azure PostgreSQL Flexible Server
variable "postgresql_server_sku" {
  description = "The SKU of the PostgreSQL Flexible Server"
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  description = "The version of the PostgreSQL Flexible Server"
  default     = "16"
}

variable "postgres_disk_size" {
  description = "The disk size of the PostgreSQL Flexible Server in MB"
  default     = 32768 # 32GB
}

variable "postgres_admin_username" {
  description = "The admin username of the PostgreSQL Flexible Server"
  default     = "fynetuneadmin"
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "The admin password of the PostgreSQL Flexible Server"
  default     = "0q09q4v8lq6KIka4Ey7A"
  sensitive   = true
}

variable "postgres_port" {
  description = "The port of the PostgreSQL Flexible Server"
  default     = 5432
}

variable "postgres_database_name" {
  description = "The name of the PostgreSQL Flexible Server database"
  default     = "fynetunedb"
}

# Azure App Service
variable "app_service_sku" {
  description = "The SKU of the App Service"
  default     = "B1"
}

variable "matomo_app_url" {
  description = "Matomo App URL"
  default     = "https://example.matomo.cloud"
}

variable "matomo_id" {
  description = "Matomo Site ID"
  default     = "1"
}

variable "okta_client_id" {
  description = "Okta Client ID"
  default     = "0oaz5"
}

variable "okta_issuer" {
  description = "Okta Issuer"
  default     = "https://dev-123456.okta.com/oauth2/default"
}

variable "okta_client_secret" {
  description = "Okta Client Secret"
  default     = "Test0q09q4v8lq6K7A"
  sensitive   = true
}

variable "splunk_org_token" {
  description = "Splunk Org Token"
  default     = "TestGklPgDgd1w"
  sensitive   = true
}

variable "splunk_realm" {
  description = "Splunk Realm"
  default     = "us1"
}

variable "splunk_url" {
  description = "Splunk URL"
  default     = "https://test.us1.signalfx.com/v2/datapoint"
}

variable "admin_email" {
  description = "Admin Email"
  default     = "admin@example.ai"
}

variable "admin_password" {
  description = "Admin Password"
  default     = "0q09q4v8lq6KIka4Ey7A"
  sensitive   = true
}

variable "static_env_variables" {
  description = "default environment variables for app service"
  default = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE : "false"
    WEBSITES_PORT : "3000"
    NEXT_PUBLIC_APP_NAME : "Fyntune AI"
    NEXT_PUBLIC_ENVIRONMENT : "production"
    AZURE_OPENAI_API_VERSION : "2023-06-01-preview"
    NEXT_PUBLIC_AZURE_OPENAI_API_VERSION : "2023-06-01-preview"
    AZURE_AISEARCH_API_VERSION : "2023-10-01-Preview"
    NEXT_PUBLIC_AZURE_AISEARCH_API_VERSION : "2023-10-01-Preview"
    AZURE_OPENAI_EMBEDDING_MODEL_NAME : "embed"
    NEXT_PUBLIC_AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME : "embed"
    HOSTING_PLATFORM : "Azure"
    NEXT_PUBLIC_ENABLE_SIGNUP : "false"
    NEXT_PUBLIC_GOOGLE_AUTH : "false"
    NEXT_PUBLIC_OKTA_AUTH : "true"
    NEXT_PUBLIC_DISALLOW_LOGIN_FROM_HOMEPAGE : "true"
    NEXTAUTH_SECRET : "secret"
  }
}
