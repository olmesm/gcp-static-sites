# GCP Static Sites

Create a static site bucket in GCP.

**NOTE** GCP Cloud Storage doesn't support custom domains with HTTPS on its own. You will need to couple this with [Cloudflare for reverse proxying](https://www.cloudflare.com/en-gb/learning/cdn/glossary/reverse-proxy/) (See [olmesm/domain-records](https://github.com/olmesm/domain-records)) or create an [HTTPS Loadbalancer](https://cloud.google.com/storage/docs/hosting-static-website)

**NOTE** Similar to above, [DNS does not support creating a CNAME record on a root domain](https://cloud.google.com/storage/docs/hosting-static-website-http#cname). [Consider CNAME flattening](https://blog.cloudflare.com/introducing-cname-flattening-rfc-compliant-cnames-at-a-domains-root/) or modifying for a [loadbalancer](https://cloud.google.com/storage/docs/hosting-static-website).

## Adding a site

Add to `./sites.yaml`. Properties marked as optional have default values below.

```yaml
example.com:
  deploy_group_name: # optional name to group deploy credentials. Creates a shared service account for sites with same `deploy_group_name`
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
  ├── scripts
      ├── .env.<deploy-group or site-name>.service-account  # Base64 encoded service account with bucket writing permissions. Contains usage information.
      └── upload-script.<site-name>.sh      # Script to facilitate static site deploy in pipelines.
  └── records
      └── domain-records.<site-name>.txt    # Zones file. Includes records for https://github.com/olmesm/domain-records tool.
```

## Deployment

#### Terraform Plan

Open a pull request and the pipeline will run. This will run a `terraform plan` step, where changes can be checked.

#### Terraform Apply

Merge/push to main and any changes on the pipeline will be mergeed to main.

## Development

Requires:

```bash
# Copy the .env.example file
cp .env.example .env
# ...and fill out the values in the .env

# Install google cloud SDK using brew or asdf
## brew
brew install --cask google-cloud-sdk
## asdf
asdf plugin add gcloud https://github.com/jthegedus/asdf-gcloud
asdf install gcloud latest
asdf global gcloud latest

# Create service account token - if fails check below
sh scripts/create-service-account-token.sh

## Might need an asdf python install to work with gcloud if above script fails and using asdf for google-sdk
asdf plugin-add python
asdf install python latest

# Install terraform using a version manager asdf or tfenv
## asdf
asdf plugin-add terraform https://github.com/Banno/asdf-hashicorp.git
asdf list-all terraform
asdf install terraform 1.3.6
asdf global terraform 1.3.6
## tfenv
brew install tfenv
tfenv install 1.3.6
tfenv use 1.3.6

# Export env
export $(xargs < .env)

# Run terraform
terraform init
terraform plan
terraform apply
```

## Troubleshooting

If experiencing domain verification errors; you likely need to add the terraform service account to the domain verification owners.

```
googleapi: Error 403: Another user owns the domain EXAMPLE.COM or a parent domain. You can either verify domain ownership at https://www.google.com/webmasters/verification/verification?domain=EXAMPLE.COM or find the current owner and ask that person to create the bucket for you, forbidden
```

Go to https://www.google.com/webmasters/verification/verification?domain=EXAMPLE.COM and add the service account (likely `tf-sa-gcp-static-sites@$GCP_PROJECT.iam.gserviceaccount.com`) email to the domain owners.
