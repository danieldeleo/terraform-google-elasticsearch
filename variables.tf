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

variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = "danny-iot-demo"
}

variable "cluster_name" {
  description = "A suffix to append to the default cluster name"
  default     = "private-elasticsearch-cluster"
}

variable "regional" {
  description = "Whether to create a regional cluster"
  default     = false
}

variable "region" {
  description = "The region to host the cluster in"
  default     = "us-central1"
}

variable "zones" {
  type        = "list"
  description = "The zone to host the cluster in (required if is a zonal cluster)"
  default     = ["us-central1-a"]
}

variable "network" {
  description = "The VPC network to host the cluster in"
  default     = "default"
}

variable "subnetwork" {
  description = "The name of subnetwork to create and host the cluster in"
  default     = "elasticsearch-subnet"
}

variable "subnetwork_ip_cidr_range" {
  description = "The ip cidr range for the cluster subnet"
  default     = "10.0.0.0/20"
}

variable "secondary_ranges" {
  type        = "list"
  description = "Two secondary ranges for GKE: one for Pods and one for Services."

  default = [
    {
      range_name    = "gke-pods-ip-range"
      ip_cidr_range = "10.4.0.0/14"
    },
    {
      range_name    = "gke-services-ip-range"
      ip_cidr_range = "10.0.16.0/20"
    },
  ]
}

variable "compute_engine_service_account" {
  description = "Service account to associate to the nodes in the cluster"
}

variable "release_name" {
  description = "The release name"
  default     = "elasticsearch-v6"
}

variable "elasticsearch_num_replicas" {
  description = "The number of Elasticsearch node replicas"
  default     = "2"
}

variable "elasticsearch_init_image" {
  description = "Image on which Elasticsearch will run"
  default     = "marketplace.gcr.io/google/elasticsearch/ubuntu16_04:6.3"
}

variable "elasticsearch_image" {
  description = "Elasticsearch image"
  default     = "marketplace.gcr.io/google/elasticsearch:6.3"
}
