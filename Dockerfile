FROM ubuntu:22.04
WORKDIR /

# Install prerequisites

RUN apt-get update && apt-get upgrade && apt-get install -y wget curl


