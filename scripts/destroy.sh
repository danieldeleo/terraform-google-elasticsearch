#!/usr/bin/env bash

cd private_cluster && \
terraform destroy --auto-approve -var-file=../terraform.tfvars