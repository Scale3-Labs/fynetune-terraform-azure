locals {

  fynetune_app_service_name = "${var.fynetune_project}-app"

  # Common tags to be assigned to all resources
  common_tags = {
    deployer         = "scale3labs"
    project_name     = var.fynetune_project
    project          = "fynetune"
    created_using    = "terraform"
    fynetune_release = var.github_release_tag
  }
}
