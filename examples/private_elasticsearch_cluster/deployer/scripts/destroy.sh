#!/usr/bin/env bash

cd /terraform-google-elasticsearch/examples/private_elasticsearch_cluster
terraform destroy -auto-approve -var project_id=$(gcloud compute project-info describe --format="value(name)")