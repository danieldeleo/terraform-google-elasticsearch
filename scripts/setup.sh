#!/usr/bin/env bash

cd private_cluster && \
terraform init && \
terraform apply -var-file=../terraform.tfvars


