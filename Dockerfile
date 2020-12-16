FROM golang:latest

RUN apt-get update -y && apt-get install -y awscli zip

# Copy in source and install deps
RUN mkdir -p /app/idp-id-broker-search
WORKDIR /app/idp-id-broker-search
COPY ./ /app/idp-id-broker-search/
