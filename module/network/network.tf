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

//module "vpc" {
//  source  = "terraform-google-modules/network/google"
//
//  project_id   = "${var.project_id}"
//  network_name = "elasticsearch-vpc"
//  routing_mode = "GLOBAL"
//
//  subnets = [
//    {
//      subnet_name           = "${var.subnetwork}"
//      subnet_ip             = "${var.subnetwork_ip_cidr_range}"
//      subnet_region         = "${var.region}"
//      subnet_private_access = "true"
//      subnet_flow_logs      = "true"
//    }
//  ]
//
//  secondary_ranges = {
//    "${var.subnetwork}" = [
//      {
//        range_name    = "gke-pods-ip-range"
//        ip_cidr_range = "10.4.0.0/14"
//      },
//      {
//        range_name    = "gke-services-ip-range"
//        ip_cidr_range = "10.0.16.0/20"
//      },
//    ]
//  }
//
//  routes = [
//    {
//      name                   = "egress-internet"
//      description            = "route through IGW to access internet"
//      destination_range      = "0.0.0.0/0"
//      tags                   = "egress-inet"
//      next_hop_internet      = "true"
//    },
//    {
//      name                   = "app-proxy"
//      description            = "route through proxy to reach app"
//      destination_range      = "10.50.10.0/24"
//      tags                   = "app-proxy"
//      next_hop_instance      = "app-proxy-instance"
//      next_hop_instance_zone = "us-west1-a"
//    },
//  ]
//}