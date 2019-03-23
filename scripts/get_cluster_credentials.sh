#!/usr/bin/env bash

terraform taint null_resource.get_cluster_credentials
terraform apply -target=null_resource.get_cluster_credentials