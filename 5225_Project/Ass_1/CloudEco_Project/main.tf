# --- Section 3: Infrastructure as Code ---

# Configure the GCP Provider
provider "google" {
  project = "composed-card-490512-r1"
  region  = "australia-southeast1" # Sydney region
}

# Define a GKE Autopilot Cluster
# Autopilot is professional and handles scaling automatically (Section 5 requirement)
resource "google_container_cluster" "primary" {
  name     = "wildlife-cluster"
  location = "australia-southeast1"

  enable_autopilot = true

  # Security best practice: release channel helps with auto-updates
  release_channel {
    channel = "REGULAR"
  }
}

# Output the cluster endpoint and name for verification
output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}