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

printf "\n// START of section auto-generated by add_cloud_shell_cidr_block.sh" >> terraform.tfvars

if [ ${DEVSHELL_IP_ADDRESS} ] ; then
  printf '\nmaster_authorized_cidr_blocks=[{
    cidr_block = "%s/32"
    display_name = "Temporary cloud shell access for setting up elasticsearch"
  }]' $DEVSHELL_IP_ADDRESS >> terraform.tfvars
else
  printf '\nmaster_authorized_cidr_blocks=[]' >> terraform.tfvars
fi

printf "\n// END of section auto-generated by add_cloud_shell_cidr_block.sh" >> terraform.tfvars