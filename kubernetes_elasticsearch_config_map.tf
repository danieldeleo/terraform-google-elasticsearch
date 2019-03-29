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


resource "kubernetes_config_map" "elasticsearch_config_map" {
  metadata {
    name = "${var.release_name}-configmap"

    labels {
      "app.kubernetes.io/name"      = "${var.release_name}"
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
}