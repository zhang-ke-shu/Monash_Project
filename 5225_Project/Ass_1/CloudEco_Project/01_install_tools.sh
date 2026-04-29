#!/bin/bash
set -euo pipefail

# ============================================================
# Step 1 - Prepare the controller VM
# ============================================================
# This VM is the admin/controller machine.
# It is NOT part of the Kubernetes cluster.
# It runs Terraform, Ansible, gcloud, kubectl, and SSH commands.

PROJECT_ID="composed-card-490512-r1"
REGION="australia-southeast1"
ZONE="australia-southeast1-a"
ANSIBLE_VENV="$HOME/ansible-venv"
SSH_KEY_PATH="$HOME/.ssh/google_compute_engine"

# ------------------------------------------------------------
# 1. Update package index and install base tools
# ------------------------------------------------------------

echo "Updating package index and installing base packages..."

sudo apt update
sudo apt install -y \
  git \
  curl \
  wget \
  unzip \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  python3 \
  python3-pip \
  python3-venv \
  openssh-client \
  jq

# ------------------------------------------------------------
# 2. Install Terraform
# ------------------------------------------------------------
# Terraform is used to provision GCP infrastructure:
# VPC, subnet, firewall rules, and 3 VM instances.

if ! command -v terraform >/dev/null 2>&1; then
  echo "Installing Terraform..."

  wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor --batch --yes | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null

  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  sudo apt update
  sudo apt install -y terraform
else
  echo "Terraform is already installed."
fi

# ------------------------------------------------------------
# 3. Install Google Cloud CLI
# ------------------------------------------------------------
# gcloud is used for authentication, SSH/SCP into GCP VMs,
# project configuration, and Artifact Registry access.

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Installing Google Cloud CLI..."

  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/cloud.google.gpg

  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null

  sudo apt update
  sudo apt install -y google-cloud-cli
else
  echo "Google Cloud CLI is already installed."
fi

# ------------------------------------------------------------
# 4. Install kubectl
# ------------------------------------------------------------
# kubectl is installed on the controller VM so this machine can
# manage the cluster after kubeconfig is copied from the master node.

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Installing kubectl..."

  sudo mkdir -p /etc/apt/keyrings

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
    sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

  sudo apt update
  sudo apt install -y kubectl
else
  echo "kubectl is already installed."
fi

# ------------------------------------------------------------
# 5. Install Ansible in a Python virtual environment
# ------------------------------------------------------------
# Installing Ansible in a dedicated virtual environment avoids
# externally-managed-environment errors on Debian/Ubuntu systems.

if [ ! -d "$ANSIBLE_VENV" ]; then
  echo "Creating Ansible virtual environment at $ANSIBLE_VENV..."
  python3 -m venv "$ANSIBLE_VENV"
else
  echo "Ansible virtual environment already exists."
fi

echo "Installing or upgrading pip and Ansible inside the virtual environment..."
"$ANSIBLE_VENV/bin/pip" install --upgrade pip
"$ANSIBLE_VENV/bin/pip" install --upgrade ansible

# Make Ansible available in the current shell session
export PATH="$ANSIBLE_VENV/bin:$PATH"

# Persist Ansible virtual environment PATH for future login shells
if ! grep -q 'export PATH="$HOME/ansible-venv/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/ansible-venv/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Persist a convenient alias for manual activation
if ! grep -q 'alias activate-ansible-venv=' "$HOME/.bashrc"; then
  echo 'alias activate-ansible-venv="source $HOME/ansible-venv/bin/activate"' >> "$HOME/.bashrc"
fi

# Ensure the current script session can use Ansible immediately
if [ -f "$ANSIBLE_VENV/bin/activate" ]; then
  # shellcheck disable=SC1090
  source "$ANSIBLE_VENV/bin/activate"
fi

# ------------------------------------------------------------
# 6. Generate SSH key if missing
# ------------------------------------------------------------
# This key is used by gcloud/SSH/Ansible to connect to the Kubernetes VMs.
# The path is aligned with later deployment scripts.

mkdir -p "$HOME/.ssh"

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Generating SSH key at $SSH_KEY_PATH..."
  ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N ""
else
  echo "SSH key already exists at $SSH_KEY_PATH."
fi

chmod 700 "$HOME/.ssh"
chmod 600 "$SSH_KEY_PATH"
chmod 644 "$SSH_KEY_PATH.pub"

# ------------------------------------------------------------
# 7. Verify installed tools
# ------------------------------------------------------------

echo "Verifying tool versions..."
terraform -version | head -n 1
gcloud --version | head -n 1
kubectl version --client=true
ansible --version | head -n 1
jq --version
ssh -V || true

# ------------------------------------------------------------
# 8. Verify Ansible is really available
# ------------------------------------------------------------

if ! command -v ansible >/dev/null 2>&1; then
  echo "ERROR: ansible is still not available in PATH."
  echo "Try running: source $ANSIBLE_VENV/bin/activate"
  exit 1
fi

echo "Ansible is available at:"
command -v ansible

# ------------------------------------------------------------
# 9. Final reminder
# ------------------------------------------------------------

echo
echo "Controller VM setup complete."
echo
echo "For future shells, you can activate the Ansible environment with:"
echo "  source $ANSIBLE_VENV/bin/activate"
echo
echo "Next step: run the authentication script or commands:"
echo "  gcloud auth login"
echo "  gcloud auth application-default login"
echo "  gcloud config set project $PROJECT_ID"
echo "  gcloud auth configure-docker $REGION-docker.pkg.dev"