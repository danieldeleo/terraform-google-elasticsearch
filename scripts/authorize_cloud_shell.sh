#!/usr/bin/env bash

# Copyright 2019 Google Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# The private cluster you created in the preceding step has a public master node
# endpoint and has master authorized networks enabled. If you want to use Cloud Shell to access the
# cluster, you must add the public IP address of your Cloud Shell to the cluster's list of master
# authorized networks.
# https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#cloud_shell
echo "Adding cloud shell public IP address to list of master authorized networks"
gcloud container clusters update ${CLUSTER} \
    --enable-master-authorized-networks \
    --zone=${CLUSTER_ZONE} \
    --master-authorized-networks=${DEVSHELL_IP_ADDRESS}/32
gcloud container clusters get-credentials ${CLUSTER} \
    --zone=${CLUSTER_ZONE}