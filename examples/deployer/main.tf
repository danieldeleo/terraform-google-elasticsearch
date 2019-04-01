provider "google" {
  project = "${var.project_id}"
  region = "${var.region}"
  zone = "${var.zones[0]}"
}

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

module "instance_template" {
  source          = "github.com/terraform-google-modules/terraform-google-vm/modules/instance_template"
  subnetwork      = "${google_compute_subnetwork.elasticsearch_subnetwork.name}"
  source_image_family = "debian-9"
  source_image_project = "debian-cloud"
  service_account = {
    email  = "${var.compute_engine_service_account}"
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_from_template" "example" {
  name = "elasticsearch-deployer"
  network_interface {
    subnetwork = "${google_compute_subnetwork.elasticsearch_subnetwork.self_link}"
    access_config {
      // Include empty nat_ip to assign external IP to allow SSH from cloud console
      nat_ip = ""
    }
  }
  source_instance_template = "${module.instance_template.self_link}"
  metadata {
    startup-script        = "${file("${path.module}/scripts/setup.sh")}"
  }
}