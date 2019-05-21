FROM golang:latest

RUN apt-get update -y && apt-get install -y awscli zip

# Install packages
RUN go get -u github.com/golang/dep/cmd/dep

# Copy in source and install deps
RUN mkdir -p /go/src/github.com/silinternational/idp-id-broker-search
WORKDIR /go/src/github.com/silinternational/idp-id-broker-search
COPY ./ /go/src/github.com/silinternational/idp-id-broker-search/
RUN dep ensure
