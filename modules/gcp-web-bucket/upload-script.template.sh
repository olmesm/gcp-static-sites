#!/bin/bash
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

# This script requires the accompanying service account
#   from `.env.service-account` or `service-account.json`to be available.
# See `.env.service-account` for more.

UPLOAD_DIRECTORY="$${1:-dist}"
SITE="$${2:-${gcp_bucket}}"

echo "[info] Uploading files from $${UPLOAD_DIRECTORY} to $${SITE}"

TEST_COMMAND=`gsutil --version &>/dev/null`
if [[ $? -ne 0 ]]; then
 echo "[error] gsutil is required but not found."
 exit 1
fi

gsutil rsync -R -d $${UPLOAD_DIRECTORY} gs://$${SITE}

echo "[info] Completed uploading to $${SITE}"

%{ if expires != null }
echo "[info] The bucket has an expiry set."
echo "[info] The content will automatically be deleted in ${expires} day${expires != "1" ? "s" : ""}."
%{ endif }