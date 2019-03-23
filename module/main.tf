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
  name                     = "${var.subnetwork}"
  project                  = "${var.project_id}"
  region                   = "${var.region}"
}

//resource "google_compute_subnetwork" "elasticsearch_subnetwork" {
//  name                     = "${var.subnetwork}"
//  ip_cidr_range            = "${var.subnetwork_ip_cidr_range}"
//  region                   = "${var.region}"
//  private_ip_google_access = "true"
//  enable_flow_logs         = "true"
//  network                  = "${var.network}"
//  project                  = "${var.project_id}"
//
//  secondary_ip_range = "${var.secondary_ranges}"
//}

module "elasticsearch_cluster" {
  source                     = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/private-cluster/"
  project_id                 = "${var.project_id}"
  name                       = "${var.cluster_name}"
  regional                   = "${var.regional}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  network                    = "${var.network}"
  subnetwork                 = "${data.google_compute_subnetwork.elasticsearch_subnetwork.name}"
  ip_range_pods              = "${data.google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range.0.range_name}"
  ip_range_services          = "${data.google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range.1.range_name}"
  service_account            = "${var.compute_engine_service_account}"
  enable_private_endpoint    = false
  enable_private_nodes       = true
  network_policy             = true
  horizontal_pod_autoscaling = true

  master_ipv4_cidr_block = "172.16.0.0/28"

  master_authorized_networks_config = [{
    cidr_blocks =  [{
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
      service_account    = "${var.compute_engine_service_account}"
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

resource "null_resource" "get_cluster_credentials" {

  provisioner "local-exec" {
    command = <<EOF
        printf "Node pools: %s" ${module.elasticsearch_cluster.node_pools_names[0]}
        bash ./scripts/wait_for_cluster.sh ${var.project_id} ${var.cluster_name}
        gcloud container clusters get-credentials ${module.elasticsearch_cluster.name} \
            --zone=${var.zones[0]} --internal-ip && \
        kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
    EOF
  }
}
//
//resource "null_resource" "remove_cloud_shell_ip_from_master_authorized_network" {
//  provisioner "local-exec" {
//    command = <<EOF
//        printf "Node pools: %s\n" ${module.elasticsearch_cluster.node_pools_names[0]}
//        bash ./scripts/wait_for_cluster.sh ${var.project_id} ${var.cluster_name}
//        gcloud container clusters update ${module.elasticsearch_cluster.name} \
//        --enable-master-authorized-networks \
//        --zone=${var.zones[0]} \
//        --master-authorized-networks=${var.subnetwork_ip_cidr_range}
//    EOF
//  }
//
//  depends_on = [
//    "kubernetes_config_map.elasticsearch_config_map",
//    "kubernetes_service.elasticsearch_service",
//    "kubernetes_stateful_set.elasticsearch_stateful_set",
//  ]
//}
//
//resource "null_resource" "update_cluster_allow_cloud_shell" {
//  triggers {
//    master-authorized-networks = "${lookup(var.master_authorized_cidr_blocks[count.index], "cidr_block")}"
//  }
//  provisioner "local-exec" {
//    command = <<EOF
//
//    gcloud container clusters update ${module.elasticsearch_cluster.name} \
//        --enable-master-authorized-networks \
//        --zone=${var.zones[0]} \
//        --master-authorized-networks=${lookup(var.master_authorized_cidr_blocks[count.index],"cidr_block")}
//
//    gcloud container clusters get-credentials ${module.elasticsearch_cluster.name} \
//        --zone=${var.zones[0]}
//    EOF
//  }
//}

data "google_client_config" "default" {}
