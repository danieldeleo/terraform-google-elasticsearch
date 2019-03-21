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
  version = "~> 1.20"
  region = "${var.region}"
}

resource "google_compute_subnetwork" "elasticsearch_subnetwork" {
  name = "${var.subnetwork}"
  ip_cidr_range = "${var.subnetwork_ip_cidr_range}"
  region = "${var.region}"
  private_ip_google_access = "true"
  enable_flow_logs = "true"
  network = "${var.network}"
  project = "${var.project_id}"

  secondary_ip_range = "${var.secondary_ranges}"
}

module "elasticsearch_cluster" {
  source = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/private-cluster"
  project_id = "${var.project_id}"
  name = "${var.cluster_name}"
  regional = false
  region = "${var.region}"
  zones = "${var.zones}"
  network = "${var.network}"
  subnetwork = "${google_compute_subnetwork.elasticsearch_subnetwork.name}"
  ip_range_pods = "${lookup(google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range[0], "range_name")}"
  ip_range_services = "${lookup(google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range[1], "range_name")}"
  service_account = "${var.compute_engine_service_account}"
  enable_private_endpoint = false
  enable_private_nodes = true
  network_policy = true
  horizontal_pod_autoscaling = true

  master_ipv4_cidr_block = "172.16.0.0/28"

  master_authorized_networks_config = [
    {
      cidr_blocks = [
        {
          cidr_block = "${data.external.get_cloud_shell_ip.result.ip}/32"
          display_name = "Temporary cloud shell access for setting up elasticsearch"
        },
      ]
    }]

  node_pools = [
    {
      name = "default-node-pool"
      machine_type = "n1-standard-2"
      min_count = 0
      max_count = 100
      disk_size_gb = 100
      disk_type = "pd-standard"
      image_type = "COS"
      auto_repair = true
      auto_upgrade = true
      service_account = "${var.compute_engine_service_account}"
      preemptible = false
      initial_node_count = 3
    },
  ]
}

resource "kubernetes_config_map" "elasticsearch_config" {
  metadata {
    name = "${var.release_name}-configmap"

    labels {
      "app.kubernetes.io/name" = "${var.release_name}"
      "app.kubernetes.io/component" = "elasticsearch-server"
    }
  }

  data {
    elasticsearch.yml = <<EOF
    cluster.name: "$${CLUSTER_NAME}"
    node.name: "$${NODE_NAME}"

    path.data: /usr/share/elasticsearch/data
    path.repo: ["$${BACKUP_REPO_PATH}"]

    network.host: 0.0.0.0

    discovery.zen.minimum_master_nodes: 2
    discovery.zen.ping.unicast.hosts: $${DISCOVERY_SERVICE}
    EOF

    log4j2.properties = <<EOF
    status = error

    appender.console.type = Console
    appender.console.name = console
    appender.console.layout.type = PatternLayout
    appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%m%n

    rootLogger.level = info
    rootLogger.appenderRef.console.ref = console
    EOF
  }

  depends_on = [
    "null_resource.get_cluster_credentials"]
}

resource "kubernetes_service" "elasticsearch_service" {
  metadata {
    name = "${var.release_name}-elasticsearch-svc"

    labels {
      "app.kubernetes.io/name" = "${var.release_name}"
      "app.kubernetes.io/component" = "elasticsearch-server"
    }

    annotations {
      "cloud.google.com/load-balancer-type" = "Internal"
    }
  }

  spec {
    port {
      name = "http"
      port = 9200
    }

    port {
      name = "tcp-transport"
      port = 9300
    }

    selector {
      "app.kubernetes.io/name" = "${var.release_name}"
      "app.kubernetes.io/component" = "elasticsearch-server"
    }

    type = "LoadBalancer"
  }

  depends_on = [
    "null_resource.get_cluster_credentials"]
}

resource "kubernetes_stateful_set" "elasticsearch_stateful_set" {
  metadata {
    name = "${var.release_name}-elasticsearch"

    labels {
      "app.kubernetes.io/name" = "${var.release_name}"
      "app.kubernetes.io/component" = "elasticsearch-server"
    }
  }

  spec {
    selector {
      match_labels {
        "app.kubernetes.io/name" = "${var.release_name}"
        "app.kubernetes.io/component" = "elasticsearch-server"
      }
    }

    service_name = "${var.release_name}-elasticsearch-svc"
    replicas = "${var.elasticsearch_num_replicas}"

    update_strategy {
      type = "OnDelete"
    }

    template {
      metadata {
        labels {
          "app.kubernetes.io/name" = "${var.release_name}"
          "app.kubernetes.io/component" = "elasticsearch-server"
        }
      }

      spec {
        termination_grace_period_seconds = 180

        init_container {
          name = "set-max-map-count"
          image = "${var.elasticsearch_init_image}"
          image_pull_policy = "IfNotPresent"
          command = [
            "/bin/bash",
            "-c",
            "if [[ \"$(sysctl vm.max_map_count --values)\" -lt 262144 ]]; then sysctl -w vm.max_map_count=262144; fi"]

          security_context {
            privileged = true
          }
        }

        container {
          name = "elasticsearch"
          image = "${var.elasticsearch_image}"
          image_pull_policy = "Always"

          env {
            name = "NODE_NAME"

            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "CLUSTER_NAME"
            value = "${module.elasticsearch_cluster.name}"
          }

          env {
            name = "DISCOVERY_SERVICE"
            value = "${var.release_name}-elasticsearch-svc"
          }

          env {
            name = "BACKUP_REPO_PATH"
            value = ""
          }

          port {
            name = "http"
            container_port = 9200
          }

          port {
            name = "tcp-transport"
            container_port = 9300
          }

          volume_mount {
            name = "configmap"
            mount_path = "/etc/elasticsearch/elasticsearch.yml"
            sub_path = "elasticsearch.yml"
          }

          volume_mount {
            name = "configmap"
            mount_path = "/etc/elasticsearch/log4j2.properties"
            sub_path = "log4j2.properties"
          }

          volume_mount {
            name = "${var.release_name}-elasticsearch-pvc"
            mount_path = "/usr/share/elasticsearch/data"
          }

          readiness_probe {
            http_get {
              path = "/_cluster/health?local=true"
              port = "9200"
            }

            initial_delay_seconds = 5
          }

          liveness_probe {
            exec {
              command = [
                "/usr/bin/pgrep",
                "-x",
                "java"]
            }

            initial_delay_seconds = 5
          }

          resources {
            requests {
              memory = "2Gi"
            }
          }
        }

        volume {
          name = "configmap"

          config_map {
            name = "${var.release_name}-configmap"
            default_mode = 420
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "${var.release_name}-elasticsearch-pvc"

        labels {
          "app.kubernetes.io/name" = "${var.release_name}"
          "app.kubernetes.io/component" = "elasticsearch-server"
        }
      }

      spec {
        access_modes = [
          "ReadWriteOnce"]
        storage_class_name = "standard"

        resources {
          requests {
            storage = "5Gi"
          }
        }
      }
    }
  }

  depends_on = [
    "null_resource.get_cluster_credentials"]
}

resource "null_resource" "get_cluster_credentials" {
  provisioner "local-exec" {
    command = <<EOF
        bash ./scripts/wait_for_cluster.sh ${var.project_id} ${var.cluster_name}
        gcloud container clusters get-credentials ${module.elasticsearch_cluster.name} \
            --zone=${var.zones[0]} && \
        kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
    EOF
  }
}

resource "null_resource" "remove_cloud_shell_ip_from_master_authorized_network" {
  provisioner "local-exec" {
    command = <<EOF
        printf "Node pools: %s" ${module.elasticsearch_cluster.node_pools_names[0]}
        bash ./scripts/wait_for_cluster.sh ${var.project_id} ${var.cluster_name}
        gcloud container clusters update ${module.elasticsearch_cluster.name} \
        --enable-master-authorized-networks \
        --zone=${var.zones[0]} \
        --master-authorized-networks=${var.subnetwork_ip_cidr_range}
    EOF
  }

  depends_on = [
    "kubernetes_config_map.elasticsearch_config",
    "kubernetes_service.elasticsearch_service",
    "kubernetes_stateful_set.elasticsearch_stateful_set",
  ]
}

data "external" "get_cloud_shell_ip" {
  program = [
    "bash",
    "./scripts/get_cloud_shell_ip.sh"]
}

data "google_client_config" "default" {}
