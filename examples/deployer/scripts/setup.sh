#!/usr/bin/env bash


sudo apt-get install unzip -y
wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip -O terraform_install.zip && \
unzip -o terraform_install.zip && \
sudo install terraform /usr/local/bin/ && \

sudo apt-get install git jq unzip kubectl -y
git clone https://github.com/danieldeleo/terraform-google-elasticsearch.git
cd terraform-google-elasticsearch
terraform init
#terraform apply -auto-approve


