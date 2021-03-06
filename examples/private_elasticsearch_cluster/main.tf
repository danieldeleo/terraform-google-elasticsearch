/**
 * Copyright 2019 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google-beta" {
  region = "${var.region}"
}

data "google_compute_subnetwork" "elasticsearch_subnetwork" {
  project = "${var.project_id}"
  region  = "${var.region}"
  name    = "${var.subnetwork}"
}

module "kubernetes_private_cluster" {
  source                     = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/private-cluster/"
  project_id                 = "${var.project_id}"
  name                       = "${var.cluster_name}"
  regional                   = "${var.regional}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  network                    = "${var.network}"
  subnetwork                 = "${var.subnetwork}"
  ip_range_pods              = "${data.google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range.0.range_name}"
  ip_range_services          = "${data.google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range.1.range_name}"
  service_account            = ""
  enable_private_endpoint    = true
  enable_private_nodes       = true
  network_policy             = true
  horizontal_pod_autoscaling = true

  master_ipv4_cidr_block = "172.16.0.0/28"

  master_authorized_networks_config = [{
    cidr_blocks = [{
      cidr_block   = "${data.google_compute_subnetwork.elasticsearch_subnetwork.ip_cidr_range}"
      display_name = "${data.google_compute_subnetwork.elasticsearch_subnetwork.name}"
    }]
  }]

  remove_default_node_pool = "true"

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 0
      max_count          = 100
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = ""
      preemptible        = false
      initial_node_count = 3
    },
  ]

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      disable-legacy-endpoints = "true"
    }
  }
}

module "kubernetes_elasticsearch_deployment" {
  source       = "../../"
  project_id   = "${var.project_id}"
  cluster_name = "${module.kubernetes_private_cluster.name}"
  host                   = "${module.kubernetes_private_cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(module.kubernetes_private_cluster.ca_certificate)}"
  token                  = "${data.google_client_config.default.access_token}"
}

data "google_client_config" "default" {}
