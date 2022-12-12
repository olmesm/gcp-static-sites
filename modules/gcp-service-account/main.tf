variable "service_name" {
  description = "The safe name of the bucket - only A-z, 0-9, -"
  type        = string
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "code_project" {
  description = "The name of the project that is being deployed"
  type        = string
  default = "Rad Website"
}

variable "google_storage_bucket_list" {
  description = "The name of the bucket."
  type        = set(string)
}

locals {
  max_length           = 28
  sa_prefix            = "dply-"
  _safe_name_short     = substr(var.service_name, 0, local.max_length - length(local.sa_prefix))
  service_account_name = "${local.sa_prefix}${local._safe_name_short}"
}

resource "google_service_account" "service_account" {
  project    = var.project
  account_id = local.service_account_name
  display_name = "${var.code_project} Service Account"
  description = "${var.code_project} Service Account"
}

resource "google_storage_bucket_iam_binding" "service_account" {
  for_each = var.google_storage_bucket_list

  bucket = each.key
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.service_account.name
}

resource "local_sensitive_file" "output_service_account_env_file" {
  content  = <<EOF
# The following secrets are added to the github secrets for the rad website
# https://github.com/radically-digital/rad-website/settings/secrets/actions
# to be used when deploying. 

BASE64_GOOGLE_APPLICATION_CREDENTIALS=${google_service_account_key.key.private_key}
GOOGLE_APPLICATION_CREDENTIALS=tmp/service-account.json
EOF
  filename = "${path.root}/output/serviceAccount/.env.${var.service_name}.service-account"
}
