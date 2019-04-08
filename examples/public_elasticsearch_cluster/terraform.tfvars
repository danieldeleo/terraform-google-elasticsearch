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

region = "us-central1"

zones = ["us-central1-a"]

network = "default"

subnetwork = "elasticsearch-subnet"

subnetwork_ip_cidr_range = "10.0.0.0/20"

secondary_ranges =  [
  {
    range_name = "gke-pods-ip-range"
    ip_cidr_range = "10.4.0.0/14"
  },
  {
    range_name = "gke-services-ip-range"
    ip_cidr_range = "10.0.16.0/20"
  },
]

cluster_name = "private-elasticsearch-cluster"

release_name = "elasticsearch-v6"

elasticsearch_num_replicas = "2"

elasticsearch_init_image = "marketplace.gcr.io/google/elasticsearch/ubuntu16_04:6.3"

elasticsearch_image = "marketplace.gcr.io/google/elasticsearch:6.3"