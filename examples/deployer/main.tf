provider "google" {}

resource "google_compute_subnetwork" "elasticsearch_subnetwork" {
  name                     = "${var.subnetwork}"
  ip_cidr_range            = "${var.subnetwork_ip_cidr_range}"
  region                   = "${var.region}"
  private_ip_google_access = "true"
  enable_flow_logs         = "true"
  network                  = "${var.network}"
  project                  = "${var.project_id}"

  secondary_ip_range = "${var.secondary_ranges}"
}

module "startup-script-lib" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-startup-scripts.git"
}

module "instance_template" {
  source          = "github.com/terraform-google-modules/terraform-google-vm/modules/instance_template"
  subnetwork      = "${var.subnetwork}"
  service_account = {
    email  = "${var.compute_engine_service_account}"
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_from_template" "example" {
  name = "elasticsearch_deployer"

  source_instance_template = "${module.instance_template.self_link}"
  metadata {
    startup-script        = "${file("${path.module}/scripts/setup.sh")}"
  }
}