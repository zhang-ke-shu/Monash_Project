# --- Section 3: Standard GKE Cluster (Assignment Compliant) ---

provider "google" {
  project = "composed-card-490512-r1"
  region  = "australia-southeast1"
}

resource "google_container_cluster" "primary" {
  name     = "wildlife-cluster"
  # We use a specific zone to ensure we can precisely control the nodes
  location = "australia-southeast1-a"

  # REQUIRED: Disable deletion protection for the new cluster as well
  deletion_protection = false

  # REQUIRED: Set initial node count to 2 (Worker Nodes)
  # In GKE, the Master Node is managed by Google but counts towards your cluster
  initial_node_count = 2

  node_config {
    # REQUIRED: 4 Cores and at least 8GB RAM
    # "e2-standard-4" provides 4 vCPU and 16GB RAM (perfectly meets the 4/8 requirement)
    machine_type = "e2-standard-4"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

output "kubernetes_cluster_name" {
  value = google_container_cluster.primary.name
}