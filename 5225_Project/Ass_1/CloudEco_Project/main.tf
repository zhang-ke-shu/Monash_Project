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
# e2-custom-4-8192 means 4 vCPUs and 8 GB RAM, matching the assignment requirement.
variable "machine_type" {
  default = "e2-custom-4-8192"
}

# -------------------------------
# VPC Network
# -------------------------------

# Create a custom VPC network for the self-managed Kubernetes cluster.
# This avoids using the default network and makes the infrastructure fully defined by Terraform.
resource "google_compute_network" "k8s_vpc" {
  name                    = "self-managed-k8s-vpc" # Name of the VPC.
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

# Allow SSH access to the Kubernetes nodes.
# This is required because the deployment script uses gcloud compute ssh to install kubeadm and configure the cluster.
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-k8s-ssh"                     # Firewall rule name.
  network = google_compute_network.k8s_vpc.name # Apply this rule to the custom VPC.

  allow {
    protocol = "tcp"  # SSH uses TCP.
    ports    = ["22"] # Port 22 is the standard SSH port.
  }

  source_ranges = ["0.0.0.0/0"] # Allow SSH from anywhere. This is convenient for testing.
  target_tags   = ["k8s-node"]  # Apply only to VMs with the k8s-node tag.
}

# Allow internal communication between Kubernetes nodes.
# Kubernetes requires nodes, pods, kubelet, container runtime, and network plugin components to communicate internally.
resource "google_compute_firewall" "allow_k8s_internal" {
  name    = "allow-k8s-internal"                # Firewall rule name.
  network = google_compute_network.k8s_vpc.name # Apply this rule to the custom VPC.

  allow {
    protocol = "tcp"       # Allow internal TCP traffic.
    ports    = ["0-65535"] # Allow all TCP ports between cluster nodes.
  }

  allow {
    protocol = "udp"       # Allow internal UDP traffic.
    ports    = ["0-65535"] # Allow all UDP ports between cluster nodes.
  }

  allow {
    protocol = "icmp" # Allow ping and other ICMP traffic for diagnostics.
  }

  source_ranges = [
    "10.10.0.0/24",  # VM subnet range.
    "192.168.0.0/16" # Pod network range used by Calico.
  ]

  target_tags = ["k8s-node"] # Apply to all Kubernetes nodes.
}

# Allow access to the Kubernetes API server.
# Port 6443 is used by kube-apiserver on the master node.
resource "google_compute_firewall" "allow_k8s_api" {
  name    = "allow-k8s-api"                     # Firewall rule name.
  network = google_compute_network.k8s_vpc.name # Apply this rule to the custom VPC.

  allow {
    protocol = "tcp"    # Kubernetes API uses TCP.
    ports    = ["6443"] # Default Kubernetes API server port.
  }

  source_ranges = ["0.0.0.0/0"]  # Allow external kubectl access during testing.
  target_tags   = ["k8s-master"] # Apply only to the master node.
}

# Allow external access to the application through NodePort.
# The Kubernetes Service exposes the FastAPI application on port 30080.
resource "google_compute_firewall" "allow_nodeport" {
  name    = "allow-wildlife-nodeport"           # Firewall rule name.
  network = google_compute_network.k8s_vpc.name # Apply this rule to the custom VPC.

  allow {
    protocol = "tcp"     # HTTP traffic uses TCP.
    ports    = ["30080"] # NodePort used by the Kubernetes Service.
  }

  source_ranges = ["0.0.0.0/0"] # Allow users and Locust clients to access the API externally.
  target_tags   = ["k8s-node"]  # Apply to all Kubernetes nodes.
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

    access_config {} # Assign an external public IP address.
  }

  tags = [
    "k8s-node",  # General tag for all Kubernetes nodes.
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
    subnetwork = google_compute_subnetwork.k8s_subnet.id # Attach VM to the same subnet as master.

    access_config {} # Assign an external public IP address.
  }

  tags = [
    "k8s-node",  # General tag for all Kubernetes nodes.
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
# This is useful for SSH, kubectl access, and checking the cluster.
output "master_external_ip" {
  value = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
}

# Output the public IP addresses of the worker nodes.
# These IPs can be used to access the NodePort service.
output "worker_external_ips" {
  value = google_compute_instance.k8s_workers[*].network_interface[0].access_config[0].nat_ip
}