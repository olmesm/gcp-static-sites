#!/bin/bash

set -e
%{ if keep_template_comments == true }
    # Note this script makes use of escape sequences.
    # 
    #   $$( .. ) is an escaped bash variable.
    #    $( .. )  is a terrafrom variable
    # 
    #   https://www.terraform.io/language/expressions/strings#escape-sequences
%{ endif }
# Defaults 
#   sh ./upload-script.sh [build_directory] [static-site-bucket]
#   sh ./upload-script.sh [dist] [${gcp_bucket}]
# Using defaults:
#   sh ./upload-script.sh
# Example if build directory is `build` then
#   sh ./upload-script.sh build

# This script requires the service account info
#   from `.env.${service_name}.service-account` to be set as environment variables.
# See `.env.${service_name}.service-account` for more.

UPLOAD_DIRECTORY="$${1:-dist}"
SITE="$${2:-${gcp_bucket}}"

TEST_COMMAND=`gsutil --version &>/dev/null`
if [[ $? -ne 0 ]]; then
 echo "[error] gsutil is required but not found."
 exit 1
fi

echo "[info] Uploading files from $${UPLOAD_DIRECTORY} to $${SITE}"

gsutil -m rsync -R -d $${UPLOAD_DIRECTORY} gs://$${SITE}

echo "[info] Completed uploading to $${SITE}"
