#!/usr/bin/env bash
set -x -e

# download gpg keys to use for signing
#runny aws s3 cp s3://$KEY_BUCKET/secret.key ./
#runny gpg --import secret.key

GOOS=linux go build -ldflags="-s -w" -o idp-id-broker-search main.go
zip idp-id-broker-search.zip idp-id-broker-search
#runny gpg --yes -a -o "idp-id-broker-search.zip.sig" --detach-sig idp-id-broker-search.zip


# Push zip to S3 under folder for CI_BRANCH (ex: develop or 1.2.3)
CI_BRANCH=${CI_BRANCH:="unknown"}
aws s3 cp idp-id-broker-search.zip s3://$DOWNLOAD_BUCKET/$CI_BRANCH/
