#!/usr/bin/env bash

sudo apt-get install git jq unzip kubectl -y
git clone https://github.com/danieldeleo/terraform-google-elasticsearch.git
cd terraform-google-elasticsearch
terraform init
#terraform apply -auto-approve

