This repository will deploy a highly-available Managed Active directory domain and a windows Compute instance to bind to the new Managed AD domain. In addition, there are optional powershell scripts to add users to the new domain and simulated a sync to Cloud Identity using Google Cloud Directory Sync.

## Costs of this deployment can quickly become an issue if left running! 

### Managed Active Directory Domain .40 per hour
### Windows GCE Instance estimate $119 per month

## Feature Highlights

- **Managed Active Directory** - The Managed Active Directory domain will be deployed with opinionated defaults for region,zone, and subnet for the Domain controllers. 

- **Isolated Windows Compute Instance** - The Windows instance will be deployed without a public IP, NAT service, and firewalls to limit access.

- **Google Cloud Directory Sync Simulation** - To demostrate the ability to  Windows instance can used to simulate the sync.

## Client Requirements

### Terraform plugins
- [Terraform](https://www.terraform.io/downloads.html) 0.12.x
- [terraform-provider-google](https://github.com/terraform-providers terraform-provider-google) plugin v2.5.0
- [terraform-provider-google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) plugin v2.5.0

### Google SDK
- [Google SDK](https://cloud.google.com/sdk)

### Microsoft RDP Client
- [Remote Desktop](https://cloud.google.com/compute/docs/instances/connecting-to-instance#windows)

### File structure
- /scripts: Helper scripts AD commands and Managed AD deployment
- /main.tf: main file for this module, contains all the resources to create
- /variables.tf: all the variables for the module
- /terraform.tfvars.template: Custom variable file to eliminate manual prompts.
- /README.MD: this file

## Google Platform Requirements

### Enable APIs
For the tutorial to work, the following APIs will be auto enabled in the project:
- Identity and Access Management API: `iam.googleapis.com`
- Compute: `compute.googleapis.com`
- Managed AD: `managedidentities.googleapis.com`
- DNS: `dns.googleapis.com`

### Service account
We need two Terraform service accounts for this module:
* **Terraform service account** (that will create the Compute Instance and NAT)
* **VM service account** (that will be created by Terraform Service account and attached to the Compute instance)

The **Terraform service account** used to run this module must have the following IAM Roles:
- `Compute Instance Admin` on the project to create the VM.
- `Project IAM Admin` on the project to grant permissions to the VM service account.



## Deploy Windows Infrastructure

1. Deploy Windows server environment with Terraform:

    ```text
    #Update terraform.tfvars.template with values for your environment
    $ cp terraform.tfvars.template terraform.tfvars
    $ terraform init
    $ terraform plan
    $ terraform apply
    ```

    This operation will take some time as it:

    1. Enables the compute and iam apis on the project
    1. Creates a windows server
    1. Creates a firewall to connect to the Managed Active Directory Domain Controllers
    1. Creates a service account with the most restrictive permissions to those resources

1. Deploy Managed Active Directory with gcloud commands
    ```text
    $ cd scripts
    $ ./deploy_managed_ad.sh <Name of your domain>
    #Wait for 25-30 minutes to deploy domain controllers & network peering

### Interact with Microsoft Active Directory Domain

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

### Optional Google Cloud Directory Sync

1. Deploy a Cloud NAT with tutorial or Terraform to download Google Cloud Directory Sync & interact with Cloud Identity.
    ```text
    https://cloud.google.com/nat/docs/using-nat

    or

    https://github.com/terraform-google-modules/terraform-google-cloud-nat
    ```
1. Powershell scripts to download and install GCDS, download Chrome browser, and add users to Active Directory.
    ```text

    #Create a user list from a Bigquery public dataset containing US names by year and state
    $ find_users_bq.bat
    
    #Create Base OU for Users & Groups
    $ create_base_ou.ps1
    
    #Create Groups
    $ Copy-Item "groups.csv" -destination "$LocalTempDir" 
    $ create_groups.ps1 
    
    #Create Users 
    $ create_users_bulk.ps1 

    #Add all the users to ALLGCPUSERS groups
    $ add_users_to_group.ps1 

    #Review Google Directory Sync Configuration instructions
    https://cloud.google.com/solutions/federating-gcp-with-active-directory-synchronizing-user-accounts
    
    #Helper ldap search rules for Users & Groups
    $ cat gdsc_ldap_rules_examples 


    ```
# Cleanup (Save Money!)

    # Destroy the windows infrastructure
    $ terraform destroy 
    # Destroy Managed Active Directory instance and Domain admin secret.
    $ ./scripts/destroy_managed_ad.sh
