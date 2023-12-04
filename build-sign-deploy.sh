#!/usr/bin/env bash
set -x -e

# download gpg keys to use for signing
#runny aws s3 cp s3://$KEY_BUCKET/secret.key ./
#runny gpg --import secret.key

# Produce a named binary for backward compatibility and a "bootstrap" binary for the provided.al2 runtime
GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w" -o idp-id-broker-search main.go
cp idp-id-broker-search bootstrap
zip idp-id-broker-search.zip idp-id-broker-search bootstrap

# Create base64 encoded sha256 checksum for terraform to use to detect changes
openssl dgst -binary -sha256 idp-id-broker-search.zip | base64 --wrap=0 > idp-id-broker-search.zip.sum

#runny gpg --yes -a -o "idp-id-broker-search.zip.sig" --detach-sig idp-id-broker-search.zip

# Push zip and checksum to S3 under folder for CI_BRANCH (ex: develop or 1.2.3)
CI_BRANCH=${CI_BRANCH:="unknown"}
bucket=$DOWNLOAD_BUCKET-${AWS_REGION}
aws s3 cp --acl public-read idp-id-broker-search.zip s3://$bucket/$CI_BRANCH/
aws s3 cp --acl public-read --content-type text/plain idp-id-broker-search.zip.sum s3://$bucket/$CI_BRANCH/

if [ -z $AWS_REGION2 ]; then
  exit 0
fi

export AWS_REGION=${AWS_REGION2}
bucket=$DOWNLOAD_BUCKET-${AWS_REGION}
aws s3 cp --acl public-read idp-id-broker-search.zip s3://$bucket/$CI_BRANCH/
aws s3 cp --acl public-read --content-type text/plain idp-id-broker-search.zip.sum s3://$bucket/$CI_BRANCH/

if [ -z $AWS_REGION3 ]; then
  exit 0
fi

export AWS_REGION=${AWS_REGION3}
bucket=$DOWNLOAD_BUCKET-${AWS_REGION}
aws s3 cp --acl public-read idp-id-broker-search.zip s3://$bucket/$CI_BRANCH/
aws s3 cp --acl public-read --content-type text/plain idp-id-broker-search.zip.sum s3://$bucket/$CI_BRANCH/

