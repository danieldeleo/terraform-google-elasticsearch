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


resource "kubernetes_stateful_set" "elasticsearch_stateful_set" {
  metadata {
    name = "${var.release_name}-elasticsearch"

    labels {
      "app.kubernetes.io/name"      = "${var.release_name}"
      "app.kubernetes.io/component" = "elasticsearch-server"
    }
  }

  spec {
    selector {
      match_labels {
        "app.kubernetes.io/name"      = "${var.release_name}"
        "app.kubernetes.io/component" = "elasticsearch-server"
      }
    }

    service_name = "${var.release_name}-elasticsearch-svc"
    replicas     = "${var.elasticsearch_num_replicas}"

    update_strategy {
      type = "OnDelete"
    }

    template {
      metadata {
        labels {
          "app.kubernetes.io/name"      = "${var.release_name}"
          "app.kubernetes.io/component" = "elasticsearch-server"
        }
      }

      spec {
        termination_grace_period_seconds = 180

        init_container {
          name              = "set-max-map-count"
          image             = "${var.elasticsearch_init_image}"
          image_pull_policy = "IfNotPresent"

          command = [
            "/bin/bash",
            "-c",
            "if [[ \"$(sysctl vm.max_map_count --values)\" -lt 262144 ]]; then sysctl -w vm.max_map_count=262144; fi",
          ]

          security_context {
            privileged = true
          }
        }

        container {
          name              = "elasticsearch"
          image             = "${var.elasticsearch_image}"
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
            name  = "CLUSTER_NAME"
            value = "${var.cluster_name}"
          }

          env {
            name  = "DISCOVERY_SERVICE"
            value = "${var.release_name}-elasticsearch-svc"
          }

          env {
            name  = "BACKUP_REPO_PATH"
            value = ""
          }

          port {
            name           = "http"
            container_port = 9200
          }

          port {
            name           = "tcp-transport"
            container_port = 9300
          }

          volume_mount {
            name       = "configmap"
            mount_path = "/etc/elasticsearch/elasticsearch.yml"
            sub_path   = "elasticsearch.yml"
          }

          volume_mount {
            name       = "configmap"
            mount_path = "/etc/elasticsearch/log4j2.properties"
            sub_path   = "log4j2.properties"
          }

          volume_mount {
            name       = "${var.release_name}-elasticsearch-pvc"
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
                "java",
              ]
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
            name         = "${var.release_name}-configmap"
            default_mode = 420
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "${var.release_name}-elasticsearch-pvc"

        labels {
          "app.kubernetes.io/name"      = "${var.release_name}"
          "app.kubernetes.io/component" = "elasticsearch-server"
        }
      }

      spec {
        access_modes = [
          "ReadWriteOnce",
        ]

        storage_class_name = "standard"

        resources {
          requests {
            storage = "5Gi"
          }
        }
      }
    }
  }
}
