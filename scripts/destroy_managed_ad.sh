#!/bin/bash
#set -x
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

if [ $# -ne 1 ]; then
    echo $0: usage: Requires argument of DomainName i.e. example.com
    exit 1
fi

export DOMAIN_NAME=$1
export STRIPPED_DOMAIN_NAME=$(echo $DOMAIN_NAME |awk -F. '{print $1}')
export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

function check_variables () {
    if [  -z "$PROJECT_ID" ]; then
        printf "ERROR: GCP PROJECT_ID is not set.\n\n"
        printf "To view the current PROJECT_ID config: gcloud config list project \n\n"
        printf "To view available projects: gcloud projects list \n\n"
        printf "To update project config: gcloud config set project PROJECT_ID \n\n"
        exit
    fi
}

function destroy_domain () {
    gcloud active-directory domains delete ${DOMAIN_NAME} 
}

function delete_password () {
    gcloud secrets delete $STRIPPED_DOMAIN_NAME --project="$PROJECT_ID" 
    
}

check_variables
destroy_domain
delete_password

