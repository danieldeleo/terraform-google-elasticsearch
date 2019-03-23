#!/usr/bin/env bash

cd private_cluster && \
terraform init && \
terraform apply --auto-approve -var-file=../terraform.tfvars

terraform init && \
terraform apply --auto-approve