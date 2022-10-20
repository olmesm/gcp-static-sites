#!/usr/bin/env bash

PROJECT_ID="rad-website-infrastructure"
ACCOUNT_NAME="rad-website@rad-website-infrastructure.iam.gserviceaccount.com"

OUTPUT=tmp/service-account.json

mkdir -p $(dirname $OUTPUT)

gcloud auth application-default login --project $PROJECT_ID --no-launch-browser

gcloud iam service-accounts keys create $OUTPUT \
  --project=$PROJECT_ID \
  --iam-account="$ACCOUNT_NAME" \
  --key-file-type=json

gcloud services enable cloudresourcemanager.googleapis.com --project $PROJECT_ID

echo "\nBASE64_GOOGLE_APPLICATION_CREDENTIALS=$(cat $OUTPUT | base64)" >> .env
echo "GOOGLE_APPLICATION_CREDENTIALS=$OUTPUT" >> .env

echo "[info] Please note you may be required to verify the domain and add the service account email ($ACCOUNT_NAME) to the owners list in https://www.google.com/webmasters/verification/details?hl=en&domain=<your.site>"