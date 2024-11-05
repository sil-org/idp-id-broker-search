#!/usr/bin/env bash
set -x -e

# Create the binary with a filename "bootstrap" as required by the provided.al2 runtime
GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w" -o bootstrap main.go
zip idp-id-broker-search.zip bootstrap

# Create base64 encoded sha256 checksum for terraform to use to detect changes
openssl dgst -binary -sha256 idp-id-broker-search.zip | base64 --wrap=0 > idp-id-broker-search.zip.sum

# Push zip and checksum to S3 under folder for GITHUB_REF_NAME (ex: develop or 1.2.3)
GITHUB_REF_NAME=${GITHUB_REF_NAME:="unknown"}
bucket=$DOWNLOAD_BUCKET-${AWS_REGION}
aws s3 cp --acl public-read idp-id-broker-search.zip s3://$bucket/$GITHUB_REF_NAME/
aws s3 cp --acl public-read --content-type text/plain idp-id-broker-search.zip.sum s3://$bucket/$GITHUB_REF_NAME/

if [ -z $AWS_REGION2 ]; then
  exit 0
fi

export AWS_REGION=${AWS_REGION2}
bucket=$DOWNLOAD_BUCKET-${AWS_REGION}
aws s3 cp --acl public-read idp-id-broker-search.zip s3://$bucket/$GITHUB_REF_NAME/
aws s3 cp --acl public-read --content-type text/plain idp-id-broker-search.zip.sum s3://$bucket/$GITHUB_REF_NAME/
