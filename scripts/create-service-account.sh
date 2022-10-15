#!/usr/bin/env bash

PARENT="$(basename $(pwd))"
PROJECT_ID="${1:-$GCP_PROJECT}"
ACCOUNT_NAME="${2:-"tf-sa-$PARENT"}"

OUTPUT=tmp/service-account.json

mkdir -p $(dirname $OUTPUT)

gcloud auth application-default login --project $PROJECT_ID --no-launch-browser

gcloud iam service-accounts create $ACCOUNT_NAME \
  --project=$PROJECT_ID \
  --description="Terraform Service Account" \
  --display-name="Terraform Service Account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --project=$PROJECT_ID \
  --member="serviceAccount:$ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts keys create $OUTPUT \
  --project=$PROJECT_ID \
  --iam-account="$ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --key-file-type=json

gcloud services enable cloudresourcemanager.googleapis.com --project $PROJECT_ID

echo "\nBASE64_GOOGLE_APPLICATION_CREDENTIALS=$(cat $OUTPUT | base64)" >> .env
echo "GOOGLE_APPLICATION_CREDENTIALS=$OUTPUT" >> .env

echo "[info] Please note you may be required to verify the domain and add the service account email ($ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com) to the owners list in https://www.google.com/webmasters/verification/details?hl=en&domain=<your.site>"