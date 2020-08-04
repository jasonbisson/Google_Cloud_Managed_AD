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
export REGION="us-central1"
export ZONE="us-central1-b"
export SUBNET="10.0.1.0/24"
export NETWORK="default"

function check_variables () {
    if [  -z "$PROJECT_ID" ]; then
        printf "ERROR: GCP PROJECT_ID is not set.\n\n"
        printf "To view the current PROJECT_ID config: gcloud config list project \n\n"
        printf "To view available projects: gcloud projects list \n\n"
        printf "To update project config: gcloud config set project PROJECT_ID \n\n"
        exit
    fi
}

function enable_services () {
    gcloud services enable managedidentities.googleapis.com
    gcloud services enable secretmanager.googleapis.com
}

function create_domain () {
    gcloud active-directory domains create ${DOMAIN_NAME} --reserved-ip-range=${SUBNET} --region=${REGION} --authorized-networks=projects/${PROJECT_ID}/global/networks/${NETWORK}
}


function reset_password () {
    STATE="CREATING"
    while [ $STATE = "CREATING" ]
    do
        echo "Sleeping for 60 seconds before checking if $DOMAIN_NAME is in a READY state"
        sleep 60
        STATE=$(gcloud active-directory domains describe $DOMAIN_NAME --format 'value(state)')
    done
    PASSWORD=$(gcloud active-directory domains reset-admin-password $DOMAIN_NAME -q --format 'value(password)')
    echo -n "${PASSWORD}" | gcloud secrets create $STRIPPED_DOMAIN_NAME --project="$PROJECT_ID" --replication-policy="automatic" --data-file=-
    
}

check_variables
enable_services
create_domain
reset_password