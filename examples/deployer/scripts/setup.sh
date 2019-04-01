#!/usr/bin/env bash


sudo apt-get install unzip git jq unzip kubectl -y

# Install Terraform
wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip -O terraform_install.zip && \
unzip -o terraform_install.zip && \
sudo install terraform /usr/local/bin/ && \

# Clone repo and create private Elasticsearch cluster
git clone https://github.com/danieldeleo/terraform-google-elasticsearch.git
cd terraform-google-elasticsearch/examples/private_elasticsearch_cluster
/usr/local/bin/terraform init
/usr/local/bin/terraform apply -auto-approve -var project_id=$(gcloud compute project-info describe --format="value(name)")


