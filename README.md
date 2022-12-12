# RAD Website Infrastructure

RAD website is hosted in a static bucket on GCP. The creation of these buckets is handled by Terraform.

Terraform also creates a service account which is used to authenticate the [RAD website project](https://github.com/radically-digital/rad-website) to deploy changes to the buckets.

**NOTE** GCP Cloud Storage doesn't support custom domains with HTTPS on its own. You will need to couple this with [Cloudflare for reverse proxying](https://www.cloudflare.com/en-gb/learning/cdn/glossary/reverse-proxy/) (See [radically-digital/domain-records](https://github.com/radically-digital/rad-domain-records)) or create an [HTTPS Loadbalancer](https://cloud.google.com/storage/docs/hosting-static-website)

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

## Deployment

Please rely on the CICD process in Github Actions to deploy infrastructure changes.

### Terraform Plan - New PR

Make changes to the Terraform code and open a pull request and the pipeline will run. This will run a `terraform plan` step, where changes can be checked and verified.

### Terraform Apply - Merge to main

Merge/push to main and the pipeline will apply any planned changes to infrastructure.
**ONLY RUN IF PLAN HAS BEEN CHECKED**

## Development

To run the project locally follow these steps.

Requires:
* Terraform and terraform version manager
* Google-cloud-sdk - for creating authentication option 2
* Access on your gsuite account to the project on GCP - for creating authentication option 2

### Copy env
Copy the .env.example file
```bash
cp .env.example .env
```

### Authentication

#### Option 1 - decode service-account.json.gpg

service-account.json.gpg contains credentials required for authentication. To decode request the passphrase to be shared to you via lastpass by one of the team and run:
```bash
gpg --quiet --batch --yes --decrypt --passphrase="{{PASSPHRASE}}" --output ./service-account.json service-account.json.gpg
```

#### Option 2 - create own service-account.json

Copy the .env.example file
```bash
cp .env.example .env
```

Install google cloud SDK using brew or asdf

brew
```bash
brew install --cask google-cloud-sdk
```

asdf
```bash
asdf plugin add gcloud https://github.com/jthegedus/asdf-gcloud
asdf install gcloud latest
asdf global gcloud latest
```

Create google service account token - if this fails check below
```bash
sh scripts/create-service-account-token.sh
```

If you are using asdf google sdk and the above  failed with a python error, you need an asdf python install to work with gcloud.
```bash
asdf plugin-add python
asdf install python latest
```

### Terraform version manager

Install terraform using a version manager asdf or tfenv

asdf
```bash
asdf plugin-add terraform https://github.com/Banno/asdf-hashicorp.git
asdf list-all terraform
asdf install terraform 1.3.6
asdf global terraform 1.3.6
```

tfenv
```bash
brew install tfenv
tfenv install 1.3.6
tfenv use 1.3.6
```

### Export env
```bash
export $(xargs < .env)
```

### Run terraform
```bash
terraform init
terraform plan
```
If you want to apply these changes it is recommended to use the Github actions CICD pipeline.
However to apply locally run.
```bash
terraform apply
```

### After run

Terraform will output the following files:

```
./output
  ├── serviceAccount
      ├── .env.<deploy-group or site-name>.service-account  # Base64 encoded service account with bucket writing permissions. Contains usage information.
  └── records
      └── domain-records.<site-name>.txt    # Zones file. Includes records for https://github.com/radically-digital/rad-domain-records.
```

## Troubleshooting

If experiencing domain verification errors; you likely need to add the terraform service account to the domain verification owners.

```
googleapi: Error 403: Another user owns the domain EXAMPLE.COM or a parent domain. You can either verify domain ownership at https://www.google.com/webmasters/verification/verification?domain=EXAMPLE.COM or find the current owner and ask that person to create the bucket for you, forbidden
```

Go to https://www.google.com/webmasters/verification/verification?domain=EXAMPLE.COM and add the service account (likely `tf-sa-gcp-static-sites@$GCP_PROJECT.iam.gserviceaccount.com`) email to the domain owners.
