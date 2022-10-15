#!/usr/bin/env bash

PARENT="$(basename $(pwd))"
PROJECT_ID="${1:-$GCP_PROJECT}"
BUCKET_NAME="tf-state-${2:-$PARENT}"

gsutil mb -p $PROJECT_ID gs://$BUCKET_NAME 
