# -------------------------------
# Google Cloud Provider
# -------------------------------

# Configure the Google Cloud provider.
# Terraform will use this provider to create and manage GCP resources.
provider "google" {
  project = var.project_id # The GCP project where all resources will be created.
  region  = var.region     # The default GCP region used by regional resources.
}

# -------------------------------
# Input Variables
# -------------------------------

# GCP project ID.
# Using a variable avoids hardcoding project information throughout the file.
variable "project_id" {
  default = "composed-card-490512-r1"
}

# GCP region for regional resources such as subnetworks.
variable "region" {
  default = "australia-southeast1"
}

# GCP zone where the virtual machines will be created.
variable "zone" {
  default = "australia-southeast1-a"
}

# VM machine type.
# e2-custom-4-8192 means 4 vCPUs and 8 GB RAM.
variable "machine_type" {
  default = "e2-custom-4-8192"
}

# -------------------------------
# VPC Network
# -------------------------------

# Create a custom VPC network for the self-managed Kubernetes cluster.
# This avoids using the default network and makes the infrastructure fully defined by Terraform.
resource "google_compute_network" "k8s_vpc" {
  name                    = "self-managed-k8s-vpc" # Name of the custom VPC.
  auto_create_subnetworks = false                  # Disable automatic subnet creation for better control.
}

# Create a subnet inside the custom VPC.
# All Kubernetes nodes will be placed in this subnet.
resource "google_compute_subnetwork" "k8s_subnet" {
  name          = "self-managed-k8s-subnet"         # Name of the subnet.
  ip_cidr_range = "10.10.0.0/24"                    # Private IP range for the VM nodes.
  region        = var.region                        # Region where the subnet is created.
  network       = google_compute_network.k8s_vpc.id # Attach this subnet to the custom VPC.
}

# -------------------------------
# Firewall Rules
# -------------------------------

# Firewall rule 1: Allow SSH access from the Internet.
# This is required so the controller VM, your local machine, or Google Cloud SSH
# can connect to the master and worker VMs.
#
# This rule targets only VMs with the k8s-node tag.
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-k8s-ssh"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Firewall rule 2: Allow external access to the Kubernetes API server.
# Port 6443 is used by the Kubernetes API server on the master node.
#
# This rule is useful for kubeadm control-plane access and cluster management.
resource "google_compute_firewall" "allow_k8s_api" {
  name    = "allow-k8s-api"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-master"]
}

# Firewall rule 3: Allow external access to the application NodePort.
# The application service exposes FastAPI through NodePort 30080.
#
# External users and Locust can access the API through:
# http://WORKER_EXTERNAL_IP:30080/docs
resource "google_compute_firewall" "allow_nodeport" {
  name    = "allow-k8s-nodeport"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["30080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Firewall rule 4: Allow internal communication between Kubernetes nodes.
# This is essential for a self-managed Kubernetes cluster.
#
# Kubernetes nodes need unrestricted internal traffic for:
# - pod-to-pod communication
# - service routing
# - kubelet communication
# - CoreDNS traffic
# - Calico networking
# - kube-proxy forwarding
# - Kubernetes control-plane and worker communication
#
# This rule does NOT expose all ports to the Internet.
# It only allows traffic where both the source and target are VMs tagged as k8s-node.
resource "google_compute_firewall" "allow_internal_k8s_node_traffic" {
  name    = "allow-k8s-internal-node-traffic"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "all"
  }

  source_tags = ["k8s-node"]
  target_tags = ["k8s-node"]
}

# Firewall rule 5: Allow health check / HTTP access if needed.
# Port 80 is optional for this project, but keeping it open is useful
# if the deployment later adds HTTP-based ingress or simple web checks.
resource "google_compute_firewall" "allow_http" {
  name    = "allow-k8s-http"
  network = google_compute_network.k8s_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# -------------------------------
# Kubernetes Master Node
# -------------------------------

# Create the master VM for the self-managed Kubernetes cluster.
# This VM will run the Kubernetes control plane after kubeadm init.
resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"     # VM name.
  machine_type = var.machine_type # 4 vCPU and 8 GB RAM.
  zone         = var.zone         # Zone where the VM is created.

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts" # Ubuntu 22.04 LTS image.
      size  = 30                                # Boot disk size in GB.
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s_subnet.id # Attach VM to the custom subnet.
    access_config {}                                     # Assign an external public IP address.
  }

  tags = [
    "k8s-node",   # General tag for all Kubernetes nodes.
    "k8s-master" # Specific tag for master firewall rules.
  ]

  service_account {
    scopes = ["cloud-platform"] # Allow the VM to access GCP services if needed.
  }
}

# -------------------------------
# Kubernetes Worker Nodes
# -------------------------------

# Create two worker VMs for the Kubernetes cluster.
# These nodes will join the cluster using kubeadm join.
resource "google_compute_instance" "k8s_workers" {
  count        = 2                               # Create exactly two worker nodes.
  name         = "k8s-worker-${count.index + 1}" # Names: k8s-worker-1 and k8s-worker-2.
  machine_type = var.machine_type                # 4 vCPU and 8 GB RAM.
  zone         = var.zone                        # Same zone as the master node.

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts" # Ubuntu 22.04 LTS image.
      size  = 30                                # Boot disk size in GB.
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s_subnet.id # Attach VM to the same custom subnet.
    access_config {}                                     # Assign an external public IP address.
  }

  tags = [
    "k8s-node",   # General tag for all Kubernetes nodes.
    "k8s-worker" # Specific tag for worker nodes.
  ]

  service_account {
    scopes = ["cloud-platform"] # Allow access to GCP services if needed.
  }
}

# -------------------------------
# Outputs
# -------------------------------

# Output the public IP address of the master node.
# This is useful for SSH and cluster management.
output "master_external_ip" {
  value = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
}

# Output the public IP addresses of the worker nodes.
# These IPs can be used to access the NodePort service.
output "worker_external_ips" {
  value = google_compute_instance.k8s_workers[*].network_interface[0].access_config[0].nat_ip
}