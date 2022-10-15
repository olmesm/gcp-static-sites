# GCP Static Sites

Create a static site bucket in GCP.

**NOTE** GCP Cloud Storage doesn't support custom domains with HTTPS on its own. You will need to couple this with [Cloudflare for reverse proxying](https://www.cloudflare.com/en-gb/learning/cdn/glossary/reverse-proxy/) (See [olmesm/domain-records](https://github.com/olmesm/domain-records)) or create an [HTTPS Loadbalancer](https://cloud.google.com/storage/docs/hosting-static-website)

**NOTE** Similar to above, [DNS does not support creating a CNAME record on a root domain](https://cloud.google.com/storage/docs/hosting-static-website-http#cname). [Consider CNAME flattening](https://blog.cloudflare.com/introducing-cname-flattening-rfc-compliant-cnames-at-a-domains-root/) or modifying for a [loadbalancer](https://cloud.google.com/storage/docs/hosting-static-website).

## Adding a site

Add to `./sites.yaml`. Properties marked as optional have default values below.

```yaml
example.com:
  main_page_suffix: "index.html" # optional
  not_found_page: "404.html" # optional
  location: "EU" # optional https://cloud.google.com/storage/docs/locations#location-mr
  allow_destroy: null # optional boolean allow bucket to be destroyed if it has objects.
  expires: null # optional number expiry in days. Also sets allow_destroy to true if allow_destroy is not explicitly set.
  cors: #TODO - https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#cors
  logging: #TODO https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#nested_logging
```

The output will be the following:

```
./output
  └── example.com
      ├── service-account.json  # Service account with bucket writing permissions.
      ├── .env.service-account  # Base64 encoded service account with bucket writing permissions. Contains usage information.
      ├── domain-records.txt    # Zones file. Includes records for https://github.com/olmesm/domain-records tool.
      └── upload-script.sh      # Script to facilitate static site deploy in pipelines.
```

## Troubleshooting

If experiencing domain verification errors; you likely need to add the terraform service account to the domain verification owners.

```
googleapi: Error 403: Another user owns the domain EXAMPLE.COM or a parent domain. You can either verify domain ownership at https://www.google.com/webmasters/verification/verification?domain=EXAMPLE.COM or find the current owner and ask that person to create the bucket for you, forbidden
```

Go to https://www.google.com/webmasters/verification/verification?domain=EXAMPLE.COM and add the service account (likely `tf-sa-gcp-static-sites@$GCP_PROJECT.iam.gserviceaccount.com`) email to the domain owners.

## Development

Requires:

- [asdf](https://asdf-vm.com)

```bash
# Install asdf dependencies
curl -sL https://raw.githubusercontent.com/olmesm/odd-scripts/main/shell/asdf-install.sh | bash

# Copy the .env.example file
cp .env.example .env
# ...and fill out the values in the .env

# Export GCP_PROJECT details
source <(curl -sL https://raw.githubusercontent.com/olmesm/odd-scripts/main/shell/env-export.sh)

# FIRST RUN ONLY: Create a new GCP Terraform service account
sh ./scripts/create-service-account.sh [GCP_PROJECT_ID] [ACCOUNT_NAME]
# ie sh ./scripts/create-service-account.sh example-website

# Setup local shell
source <(curl -sL https://raw.githubusercontent.com/olmesm/odd-scripts/main/shell/env-export.sh)

# Setup credentials
sh ./scripts/decode-service-account-from-env.sh

# Create state bucket
sh scripts/create-terraform-state-bucket.sh [GCP_PROJECT_ID] [BUCKET_NAME]
# ie sh scripts/create-terraform-state-bucket.sh

terraform init
terraform plan
terraform apply
```
