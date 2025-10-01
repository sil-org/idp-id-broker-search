FROM golang:1.25

RUN apt-get update -y && \
    apt-get --no-install-recommends install -y awscli zip

# set up to run as a normal user
RUN useradd user && mkdir /home/user && chown user:user /home/user
USER user
ENV GOPATH=/home/user/go

# Copy in source and install deps
WORKDIR /home/user
COPY --chown=user main.go main_test.go go.mod go.sum build-sign-deploy.sh /home/user/
COPY --chown=user shared/types.go  /home/user/shared/
