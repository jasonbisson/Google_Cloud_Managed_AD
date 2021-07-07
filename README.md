This repository will deploy a highly-available Managed Active directory domain and a windows Compute instance to bind to the new Managed AD domain. In addition, there are optional powershell scripts to add users to the new domain and simulated a sync to Cloud Identity using Google Cloud Directory Sync.

## Costs of this deployment can quickly become an issue if left running! 

### Managed Active Directory Domain .40 per hour
### Windows GCE Instance estimate $119 per month

## Feature Highlights

- **Managed Active Directory** - The Managed Active Directory domain will be deployed with opinionated defaults for region,zone, and subnet for the Domain controllers. 

- **Isolated Windows Compute Instance** - The Windows instance will be deployed without a public IP, NAT service, and firewalls to limit access.

- **Google Cloud Directory Sync Simulation** - To demostrate the ability to  Windows instance can used to simulate the sync.

## Prerequisites

### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) 0.13.x
- [terraform-provider-google](https://github.com/terraform-providers terraform-provider-google) plugin 3.50

### Google SDK
- [Google SDK](https://cloud.google.com/sdk)

### Microsoft RDP Client
- [Remote Desktop](https://cloud.google.com/compute/docs/instances/connecting-to-instance#windows)

## Update variables

1. Change to deployment directory
   ```
   cd envs/development
   ```
1. Update `backend.tf` with an existing GCS bucket to store Terraform state.
   ```
   bucket = "UPDATE_ME"
   ```
1. Rename `terraform.example.tfvars` to `terraform.tfvars` and update the file with values from your environment:
   ```
   mv terraform.example.tfvars terraform.tfvars


## Deploy Infrastructure

### Deploy from a desktop

1. Run `terraform init`
1. Run `terraform plan` and review the output.
1. Run `terraform apply`

**Note** Managed Active Directory deployment can take up to 60 minutes

### Optional Deploy a Cloud Build environment

1. Deploy Bootstrap environment from [Cloud Foundation Toolkit](https://github.com/terraform-google-modules/terraform-example-foundation/tree/master/0-bootstrap)

1. Add cloud_source_repos to terraform.tfvars file to build gcp-gcds repo in 0-bootstrap

   ```
   cloud_source_repos = ["gcp-org", "gcp-environments", "gcp-networks", "gcp-projects", "gcp-gcds"]
   ```
1. Run `terraform apply`

#### Deploy from Cloud Build pipeline

1. Clone the empty gcp-gcds repo.
   ```
   gcloud source repos clone gcp-gcds --project=YOUR_CLOUD_BUILD_PROJECT_ID_FROM_0-bootstrap
   ```
1. Navigate into the repo and change to a non-production branch.
   ```
   cd gcp-gcds
   git checkout -b plan
   ```
1. Copy the development environment directory and cloud build configuration files
   ```
   cp -r ../gcp-gcds-validator/envs  .
   cp ../gcp-gcds-validator/build/*  . 
   ```
1. Ensure wrapper script can be executed.
   ```
   chmod 755 ./tf-wrapper.sh
   ```
1. Commit changes.
   ```
   git add .
   git commit -m 'Your message'
   ```
1. Push your plan branch to trigger a plan. For this command, the branch `plan` is not a special one. Any branch which name is different from `development`, `non-production` or `production` will trigger a Terraform plan.
   ```
   git push --set-upstream origin plan
   ```
1. Review the plan output in your Cloud Build project. https://console.cloud.google.com/cloud-build/builds?project=YOUR_CLOUD_BUILD_PROJECT_ID
1. Merge changes to production branch.
   ```
   git checkout -b development
   git push origin development
   ```
1. Review the apply output in your Cloud Build project. https://console.cloud.google.com/cloud-build/builds?project=YOUR_CLOUD_BUILD_PROJECT_ID

1. Destroy the new GCS bucket with gcloud build command
   ```
   gcloud builds submit . --config=cloudbuild-tf-destroy.yaml --project your_build_project_id --substitutions=BRANCH_NAME="$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')",_ARTIFACT_BUCKET_NAME='Your Artifact GCS Bucket',_STATE_BUCKET_NAME='Your Terraform GCS bucket',_DEFAULT_REGION='us-central1',_GAR_REPOSITORY='prj-tf-runners'
   ```

## Interact with Microsoft Active Directory Domain

1. Start an Identity Aware Proxy tunnel & start remote desktop session
    ```text
    $ gcloud compute start-iap-tunnel <Name Of Windows Server> 3389 --local-host-port=localhost:3389 --zone=us-central1-b
    ```
1. Login with local account creditials and reset password in UI or gcloud cli
    ``` text
    $ gcloud compute reset-windows-password <Name of Windows Server> --zone=us-central1-b
    ```
1. Retrieve the Domain administrator password from Secrets Manager in UI or gcloud cli
    ``` text
    $ gcloud secrets versions access latest --secret="<name of domain without suffix>" --format json
    ```
1. Add Server to the new Active Directory domain
    ```text
    Open a Powershell session to run as Administrator
    $  $domainname = read-host -Prompt "Please enter a domainname" 
    $  Add-Computer -DomainName $domainname -Credential $domainname\setupadmin -Restart -Force 
    Enter Domain password 
    ```
1. Confirm server joined domain

    1. Log back into server with <Name of domain>\setupadmin
    1. Click on Windows Administrative Tools and Click on Active Directory Users and Computers
    1. Click on Name of domain -> Cloud -> Computers
    1. Click on Domain Controllers to view the domain controllers
    1. Add users or groups under the Cloud OU or groups under the Cloud OU


## Google Cloud Directory Sync demo
  1. Copy scripts onto the windows server with either git or gsutil commands.

  1. Create a user list from a Bigquery public dataset containing US names by year and state
     $ find_users_bq.bat
    
  1. Create Base OU for Users & Groups
     $ create_base_ou.ps1
    
  1. Create Groups
     $ Copy-Item "groups.csv" -destination C:\Windows\temp\
     $ create_groups.ps1 
    
  1. Create Users 
     $ create_users_bulk.ps1 

  1. Add all the users to ALLGCPUSERS groups
     $ add_users_to_group.ps1 

  1. Review Google Directory Sync Configuration instructions
    https://cloud.google.com/solutions/federating-gcp-with-active-directory-synchronizing-user-accounts
    
  1. Helper ldap search rules for Users & Groups
    $ cat gdsc_ldap_rules_examples 
    
  1. Validate the sync, but don't apply 

    ```
# Cleanup (Save Money!)

    # Destroy the windows infrastructure
    $ terraform destroy or Cloud build to destroy
