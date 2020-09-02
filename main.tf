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

terraform {
  required_version = ">= 0.12"
  backend "gcs" {}
}

provider "google" {
  version = "~> 3.0.0"
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

module "cloud-nat" {
  source     = "../terraform-google-cloud-nat/"
  router     = var.router
  project_id = var.project_id
  region     = var.region
  network   = var.network
  create_router = var.create_router
}


resource "google_project_service" "project_services" {
  count                      = var.enable_apis ? length(var.activate_apis) : 0
  service                    = element(var.activate_apis, count.index)
  disable_on_destroy         = var.disable_services_on_destroy
  disable_dependent_services = var.disable_dependent_services
}


data "google_compute_image" "image" {
  family  = "${var.source_image_family}"
  project = "${var.source_image_project}"
}

data "template_file" "startup_script_config" {
  template = "${file("${path.module}/scripts/startup.ps1")}"
}
resource "random_id" "service_account" {
  byte_length = 2
}

resource "google_service_account" "service_account" {
  account_id   = "${var.environment}${random_id.service_account.hex}"
  display_name = "GCE service account for ${var.environment}${random_id.service_account.hex}"
}

resource "google_project_iam_member" "Compute_admin" {
  project = "${var.project}"
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "source_reader" {
  project = "${var.project}"
  role    = "roles/source.reader"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "Storage_viewer" {
  project = "${var.project}"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "bigquery_viewer" {
  project = "${var.project}"
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_compute_instance" "default" {
  name         = "${var.environment}${random_id.service_account.hex}"
  machine_type = "${var.machine_type}"
  labels       = "${var.labels}"


  tags           = ["${var.environment}"]
  can_ip_forward = "${var.can_ip_forward}"

  service_account {
    email  = "${google_service_account.service_account.email}"
    scopes = ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.image.self_link}"
      size  = "${var.disk_size_gb}"
      type  = "${var.disk_type}"
    }
  }

  metadata = {
    windows-startup-script-ps1 = "${data.template_file.startup_script_config.rendered}"
  }

  network_interface {
    subnetwork = "${var.ip_subnetworks}"
  }

  lifecycle {
    create_before_destroy = "false"
  }
}

resource "google_compute_firewall" "default" {
  name        = "${var.environment}${random_id.service_account.hex}"
  description = "GCE Firewall for ${var.environment}"
  network     = "${var.network}"
  priority    = 1000
  direction   = "EGRESS"
  target_tags = ["${var.environment}"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  destination_ranges = "${var.internal_cidr_ranges}"
}