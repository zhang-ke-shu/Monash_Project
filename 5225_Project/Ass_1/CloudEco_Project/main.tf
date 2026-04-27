# --- Provider ---
provider "google" {
  project = "composed-card-490512-r1"
  region  = "australia-southeast1"
}

# --- GKE Cluster ---
resource "google_container_cluster" "primary" {
  name     = "wildlife-cluster"
  location = "australia-southeast1-a"

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}
}

# --- Node Pool ---
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = "australia-southeast1-a"
  node_count = 2

  node_config {
    machine_type = "e2-custom-4-8192"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# --- Output ---
output "kubernetes_cluster_name" {
  value = google_container_cluster.primary.name
}