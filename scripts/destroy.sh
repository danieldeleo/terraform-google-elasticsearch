#!/usr/bin/env bash

terraform destroy --auto-approve

cd examples/private_cluster && \
terraform destroy --auto-approve -var-file=../terraform.tfvars

