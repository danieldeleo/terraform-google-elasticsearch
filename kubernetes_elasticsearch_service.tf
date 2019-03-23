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


resource "kubernetes_service" "elasticsearch_service" {
  metadata {
    name = "${var.release_name}-elasticsearch-svc"

    labels {
      "app.kubernetes.io/name"      = "${var.release_name}"
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
      "app.kubernetes.io/name"      = "${var.release_name}"
      "app.kubernetes.io/component" = "elasticsearch-server"
    }

    type = "LoadBalancer"
  }

  depends_on = [
    "null_resource.cloudshell_master_access",
  ]
}