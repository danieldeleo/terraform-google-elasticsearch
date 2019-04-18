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

provider "google" {
  version = "2.3"
  region = "${var.region}}"
}

provider "google-beta" {
  version = "2.3"
  region = "${var.region}"
}

resource "google_compute_subnetwork" "elasticsearch_subnetwork" {
  name                     = "${var.subnetwork}"
  ip_cidr_range            = "${var.subnetwork_ip_cidr_range}"
  region                   = "${var.region}"
  private_ip_google_access = "true"
  enable_flow_logs         = "true"
  network                  = "${var.network}"
  project                  = "${var.project_id}"

  secondary_ip_range = "${var.secondary_ranges}"
}

module "kubernetes_public_cluster" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = "${var.project_id}"
  name                       = "${var.cluster_name}"
  regional                   = "${var.regional}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  network                    = "${var.network}"
  subnetwork                 = "${google_compute_subnetwork.elasticsearch_subnetwork.name}"
  ip_range_pods              = "${lookup(google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range[0], "range_name")}"
  ip_range_services          = "${lookup(google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range[1], "range_name")}"
  service_account            = ""
  network_policy             = true
  horizontal_pod_autoscaling = true

  remove_default_node_pool = true

  node_pools = [
    {
      name               = "elasticsearch-node-pool"
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

  node_pools_oauth_scopes = {
    all = []
    elasticsearch-node-pool = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  node_pools_taints = {
    all = []
    elasticsearch-node-pool = []
  }
  node_pools_tags = {
    all = []
    elasticsearch-node-pool = ["elasticsearch-node-pool"]
    default-node-pool = ["default-node-pool"]
  }
  node_pools_labels = {
    all={}
    elasticsearch-node-pool = {
      default-node-pool = "false"
    }

  }

  node_pools_metadata = {
    all = {}
    elasticsearch-node-pool = {}
  }
}

module "kubernetes_elasticsearch_deployment" {
  source       = "../../"
  project_id   = "${var.project_id}"
  cluster_name = "${module.kubernetes_public_cluster.name}"
  host                   = "${module.kubernetes_public_cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(module.kubernetes_public_cluster.ca_certificate)}"
  token                  = "${data.google_client_config.default.access_token}"
}

data "google_client_config" "default" {}
