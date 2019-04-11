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
}

variable "host" {
  description = "Endpoint of the Master on the Kubernetes cluster"
}

variable "cluster_ca_certificate" {
  description = "CA certificate of the kubernetes cluster"
}

variable "token" {
  description = "Access token for accessing the Kubernetes Master"
}

variable "cluster_name" {
  description = "The name of the kubernetes cluster on which Elasticsearch will deploy"
  default     = "private-elasticsearch-cluster"
}

variable "region" {
  description = "Region of the cluster"
  default = "us-central1"
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
