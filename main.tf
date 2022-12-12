terraform {
  backend "gcs" {
    bucket = "tf-state-rad-website-infrastructure-c0d136"
    prefix = "terraform/cloudflare_state"
  }
}

terraform {
  required_providers {
    gcp = {
      source  = "hashicorp/google"
      version = "4.26.0"
    }
  }
  required_version = "~> 1.3.6"
}

variable "google_project_name" {
  description = "TF_VAR_google_project_name"
  type        = string
}

provider "google" {
  project = var.google_project_name
}

locals {
  yaml_values = yamldecode(file("${path.module}/sites.yaml"))
  map_list = { for key, values in local.yaml_values : key => merge({
    location          = "EU"
    main_page_suffix  = "index.html"
    not_found_page    = "404.html"
    deploy_group_name = key

    expires       = null
    allow_destroy = null
  }, values) }
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.google_project_name
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "iam" {
  project = var.google_project_name
  service = "iam.googleapis.com"
}

module "web_bucket" {
  source = "./modules/gcp-web-bucket"

  for_each = local.map_list

  project          = var.google_project_name
  name             = each.key
  location         = each.value["location"]
  main_page_suffix = each.value["main_page_suffix"]
  not_found_page   = each.value["not_found_page"]
  expires          = each.value["expires"]

  depends_on = [
    google_project_service.cloudresourcemanager,
    google_project_service.iam
  ]
}

locals {
  service_accounts = transpose({ for key, values in module.web_bucket : values["bucket_name"] =>
    [replace(local.map_list[key]["deploy_group_name"], ".", "-")]
  })
}

module "upload_script" {
  source = "./modules/gcp-upload-script"

  for_each = local.service_accounts

  project                    = var.google_project_name
  service_name               = each.key
  google_storage_bucket_list = each.value
}