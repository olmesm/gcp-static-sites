#!/usr/bin/env bash

PARENT="$(basename $(pwd))"
PROJECT_ID="${1:-$GCP_PROJECT}"
RANDOM_SUFFIX=$(echo "$RANDOM `date`" | md5sum | head -c 6)
BUCKET_NAME="tf-state-${2:-$PARENT}-$RANDOM_SUFFIX"

gsutil mb -p $PROJECT_ID gs://"$BUCKET_NAME"

perl -i -pe "s|bucket *= *\".*\"|bucket = \"$BUCKET_NAME\"|" main.tf
