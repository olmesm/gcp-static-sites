terraform {
  required_providers {
    gcp = {
      source  = "hashicorp/google"
      version = "4.26.0"
    }
  }
}

variable "name" {
  description = "The name of the bucket"
  type        = string
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "google_storage_bucket_name" {
  description = "The name of the bucket."
  type        = string
}

locals {
  max_length           = 28
  sa_prefix            = "dply-"
  safe_name            = replace(var.name, ".", "-")
  safe_name_short      = substr(local.safe_name, 0, local.max_length - length(local.sa_prefix))
  service_account_name = "${local.sa_prefix}${local.safe_name_short}"
}

resource "google_service_account" "service_account" {
  project    = var.project
  account_id = local.service_account_name
}

resource "google_storage_bucket_iam_binding" "service_account" {
  bucket = var.google_storage_bucket_name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.service_account.name
}

resource "local_file" "output_script" {
  content = templatefile("${path.module}/upload-script.template.sh", {
    gcp_bucket             = var.google_storage_bucket_name
    keep_template_comments = false
    expires                = var.expires
  })

  filename = "${path.root}/output/${local.safe_name}/script/upload-script.sh"
}

resource "local_sensitive_file" "output_service_account" {
  content  = base64decode(google_service_account_key.key.private_key)
  filename = "${path.root}/output/${local.safe_name}/script/service-account.json"
}

resource "local_sensitive_file" "output_service_account_env_file" {
  content  = <<EOF
# Add the following variables to your env and 
#   use the script https://github.com/olmesm/odd-scripts/blob/main/shell/gcp-service-account-base64-decode-from-env.sh
#   to facilitate the deploy. 
# See in use example https://github.com/olmesm/domain-records/blob/main/.github/workflows/main.yaml

BASE64_GOOGLE_APPLICATION_CREDENTIALS=${google_service_account_key.key.private_key}
GOOGLE_APPLICATION_CREDENTIALS=tmp/service-account.json
EOF
  filename = "${path.root}/output/${local.safe_name}/script/.env.service-account"
}
