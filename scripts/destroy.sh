#!/usr/bin/env bash

terraform init && terraform destroy -auto-approve

cd examples/private_cluster && \
terraform init && terraform destroy -auto-approve -var-file=../../terraform.tfvars

