provider "google-beta" {
  region = "${var.region}"
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

module "elasticsearch_cluster" {
  source                     = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/private-cluster/"
  project_id                 = "${var.project_id}"
  name                       = "${var.cluster_name}"
  regional                   = "${var.regional}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  network                    = "${var.network}"
  subnetwork                 = "${google_compute_subnetwork.elasticsearch_subnetwork.name}"
  ip_range_pods              = "${lookup(google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range[0], "range_name")}"
  ip_range_services          = "${lookup(google_compute_subnetwork.elasticsearch_subnetwork.secondary_ip_range[1], "range_name")}"
  service_account            = "${var.compute_engine_service_account}"
  enable_private_endpoint    = false
  enable_private_nodes       = true
  network_policy             = true
  horizontal_pod_autoscaling = true

  master_ipv4_cidr_block = "172.16.0.0/28"

  master_authorized_networks_config = [{
    cidr_blocks = "${var.master_authorized_cidr_blocks}"
  }]

  remove_default_node_pool = "true"
  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 0
      max_count          = 100
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "${var.compute_engine_service_account}"
      preemptible        = false
      initial_node_count = 3

    },
  ]

  node_pools_metadata = {
    all = {}
    default-node-pool = {
      disable-legacy-endpoints = "true"
    }
  }
}