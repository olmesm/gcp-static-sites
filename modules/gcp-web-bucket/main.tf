variable "name" {
  description = "The name of the bucket"
  type        = string
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "location" {
  description = "The GCS location https://cloud.google.com/storage/docs/locations"
  type        = string
  default     = "EU"
}

variable "main_page_suffix" {
  description = "The bucket's directory index where missing objects are treated as potential directories"
  type        = string
  default     = "index.html"
}

variable "not_found_page" {
  description = "The custom object to return when a requested resource is not found."
  type        = string
  default     = "404.html"
}

variable "allow_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
  type        = bool
  default     = null
}

variable "expires" {
  description = "Set expiry in days"
  type        = string
  default     = null
}

locals {
  safe_name = replace(var.name, ".", "-")

  _url        = split(".", var.name)
  _domain     = slice(local._url, length(local._url) - 2, length(local._url))
  _sub_domain = local._url == local._domain ? [""] : slice(local._url, 0, length(local._url) - 2)

  domain      = join(".", local._domain)
  sub_domain  = join(".", local._sub_domain)
  full_domain = join(".", compact([local.sub_domain, local.domain]))
}

resource "google_storage_bucket" "default" {
  project                     = var.project
  name                        = var.name
  location                    = var.location
  force_destroy               = var.allow_destroy != null ? var.allow_destroy : var.expires != null ? true : false
  uniform_bucket_level_access = true

  website {
    main_page_suffix = var.main_page_suffix
    not_found_page   = var.not_found_page
  }

  dynamic "lifecycle_rule" {
    for_each = var.expires != null ? [var.expires] : []

    content {
      condition {
        age = lifecycle_rule.value
      }

      action {
        type = "Delete"
      }
    }
  }
}

resource "google_storage_bucket_iam_binding" "public" {
  bucket = google_storage_bucket.default.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers",
  ]
}

resource "local_file" "output_record" {
  content  = <<EOF
;; For use with https://github.com/radically-digital/rad-domain-records
;; the following is a valid yaml record
;;
;;   ${local.domain}:
;;     - name: ${local.sub_domain != "" ? local.sub_domain : local.domain}
;;       type: CNAME
;;       value: c.storage.googleapis.com
;;       proxied: true
;;
;; ---------
;;
;; For further information regarding this file, please consult the BIND documentation
;; located on the following website:
;;
;; http://www.isc.org/
;;
;; And RFC 1035:
;;
;; http://www.ietf.org/rfc/rfc1035.txt
;;
;; Please note that we do NOT offer technical support for any use
;; of this zone data, the BIND name server, or any other third-party
;; DNS software.
;;
;; Use at your own risk.

${local.full_domain}.	1	IN	CNAME	c.storage.googleapis.com.
EOF
  filename = "${path.root}/output/records/domain-records.${local.safe_name}.txt"
}

output "bucket_name" {
  value       = google_storage_bucket.default.name
  description = "Created bucket name"
}