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

provider "google-beta" {}

//resource "null_resource" "get_cluster_credentials" {
//
//  provisioner "local-exec" {
//    command = <<EOF
//        bash ./scripts/wait_for_cluster.sh ${var.project_id} ${var.cluster_name}
//        gcloud container clusters get-credentials ${module.elasticsearch_cluster.name} \
//            --zone=${var.zones[0]} && \
//        kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
//    EOF
//  }
//}
//
resource "null_resource" "remove_cloud_shell_ip_from_master_authorized_network" {
  provisioner "local-exec" {
    command = <<EOF
        gcloud container clusters update ${var.cluster_name} \
        --enable-master-authorized-networks \
        --zone=${var.zones[0]} \
    EOF
  }

  depends_on = [
    "kubernetes_config_map.elasticsearch_config_map",
    "kubernetes_service.elasticsearch_service",
    "kubernetes_stateful_set.elasticsearch_stateful_set",
  ]
}

resource "null_resource" "get_cluster_credentials" {
  provisioner "local-exec" {
    command = <<EOF

    gcloud container clusters update ${var.cluster_name} \
        --enable-master-authorized-networks \
        --zone=${var.zones[0]} \
        --master-authorized-networks=$${DEVSHELL_IP_ADDRESS}/32

    gcloud container clusters get-credentials ${var.cluster_name} \
        --zone=${var.zones[0]}
    EOF
  }
}

data "google_client_config" "default" {}
