# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "environment" {
  description = "Environment for the environment"
}

variable "project" {
  description = "The ID of the project where this VPC will be created"
}

variable "active_directory_domain" {
  description = "Domainname of Managed Active Directory instance"
}

variable "terraform_service_account" {
  description = "Service account email of the account to impersonate to run Terraform."
  type        = string
  default     = ""
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-b"
}

variable "machine_type" {
  description = "Machine type to deploy Splunk"
  default     = "n1-standard-2"
}

variable "can_ip_forward" {
  description = "Enable IP forwarding, for NAT instances for example"
  default     = "false"
}

variable "labels" {
  type        = map
  description = "Labels, provided as a map"
  default     = {}
}

variable "source_image_family" {
  description = "Source image family. If neither source_image nor source_image_family is specified."
  default     = "windows-2016"
}

variable "source_image_project" {
  description = "Project where the source image comes from"
  default     = "windows-cloud"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  default     = "100"
}

variable "disk_type" {
  description = "Boot disk type, can be either pd-ssd, local-ssd, or pd-standard"
  default     = "pd-standard"
}

variable "auto_delete" {
  description = "Whether or not the boot disk should be auto-deleted"
  default     = "true"
}

variable "network" {
  description = "Network for deployment of GCE instance and peering for Managed AD Instance"
  type        = string
  default     = "default"
}

variable "internal_cidr_ranges" {
  type        = list
  description = "Firewall rule to connect to Managed AD instance"
}

variable "reserved_ip_range" {
  type        = string
  description = "Subnet range to deploy domain controllers of Managed AD instance"
}


variable "enable_apis" {
  description = "Whether to actually enable the APIs. If false, this module is a no-op."
  default     = "true"
}

variable "activate_apis" {
  description = "The list of apis to activate within the project"
  default     = ["iam.googleapis.com", "compute.googleapis.com", "dns.googleapis.com", "managedidentities.googleapis.com"]
  type        = list(string)
}

variable "disable_services_on_destroy" {
  description = "Whether project services will be disabled when the resources are destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_on_destroy"
  default     = "false"
  type        = string
}

variable "disable_dependent_services" {
  description = "Whether services that are enabled and which depend on this service should also be disabled when this service is destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_dependent_services"
  default     = "false"
  type        = string
}

variable "create_router" {
  description = "Create the cloud router"
  default     = "true"
  type        = string
}
