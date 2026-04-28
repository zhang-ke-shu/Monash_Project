#!/bin/bash
set -e

# ============================================================
# Configuration variables
# ============================================================

PROJECT_ID="composed-card-490512-r1"
REGION="australia-southeast1"
ZONE="australia-southeast1-a"

REPO_NAME="wildlife-repo"
IMAGE_NAME="wildlife-api"
TAG="vm-v6"

# Existing image in Artifact Registry
AR_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"

MASTER_NAME="k8s-master"
WORKER1_NAME="k8s-worker-1"
WORKER2_NAME="k8s-worker-2"

echo "Starting self-managed Kubernetes deployment using existing image: $AR_PATH"

# ============================================================
# 0. Install required local tools
# ============================================================

echo "Checking and installing required local tools..."

sudo apt update
sudo apt install -y \
  git \
  curl \
  wget \
  unzip \
  gnupg \
  software-properties-common \
  python3-pip \
  python3-venv \
  apt-transport-https \
  ca-certificates

# Install Terraform if missing
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."

    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt update
    sudo apt install -y terraform
else
    echo "Terraform is already installed."
fi

# Install Google Cloud CLI if missing
if ! command -v gcloud &> /dev/null; then
    echo "Installing Google Cloud CLI..."

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

    sudo apt update
    sudo apt install -y google-cloud-cli
else
    echo "Google Cloud CLI is already installed."
fi

# Install kubectl if it is not already installed on the current machine.
# This is required because the script later runs kubectl locally
# using the kubeconfig copied from the master node.
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl on current machine..."

    sudo mkdir -p /etc/apt/keyrings

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt update
    sudo apt install -y kubectl
else
    echo "kubectl is already installed on current machine."
fi

echo "Tool versions:"
terraform -version
gcloud --version | head -n 1
kubectl version --client

# ============================================================
# 1. Check GCP authentication
# ============================================================

echo "Checking GCP authentication..."

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "No active gcloud account found."
    echo "Please run these commands first:"
    echo "gcloud auth login"
    echo "gcloud auth application-default login"
    exit 1
fi

echo "Using existing gcloud authentication."

gcloud config set project $PROJECT_ID

# Configure Docker credential helper for Artifact Registry.
# This is still useful because Kubernetes nodes may need access to the image registry.
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

# ============================================================
# 2. Provision infrastructure with Terraform
# ============================================================

echo "Running Terraform..."

terraform init
terraform validate
terraform apply -auto-approve

# ============================================================
# 3. Skip Docker build and push
# ============================================================

echo "Skipping Docker build and push."
echo "Using existing image: $AR_PATH"

# ============================================================
# 4. Install Kubernetes components on all VMs
# ============================================================

echo "Installing Kubernetes components on all VMs..."

for VM in $MASTER_NAME $WORKER1_NAME $WORKER2_NAME
do
    echo "Configuring $VM..."

    gcloud compute ssh $VM --zone $ZONE --command='
        set -e

        sudo apt update
        sudo apt install -y containerd apt-transport-https ca-certificates curl gpg

        sudo swapoff -a
        sudo sed -i "/ swap / s/^/#/" /etc/fstab

        sudo modprobe overlay
        sudo modprobe br_netfilter

        cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

        sudo sysctl --system

        sudo mkdir -p /etc/containerd
        containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
        sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/" /etc/containerd/config.toml
        sudo systemctl restart containerd
        sudo systemctl enable containerd

        sudo mkdir -p /etc/apt/keyrings

        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
        sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
        sudo tee /etc/apt/sources.list.d/kubernetes.list

        sudo apt update
        sudo apt install -y kubelet kubeadm kubectl
        sudo apt-mark hold kubelet kubeadm kubectl
    '
done

# ============================================================
# 5. Initialise Kubernetes master node
# ============================================================

echo "Initialising Kubernetes master node..."

gcloud compute ssh $MASTER_NAME --zone $ZONE --command='
    set -e

    sudo kubeadm reset -f || true

    sudo kubeadm init --pod-network-cidr=192.168.0.0/16

    mkdir -p $HOME/.kube
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml

    kubeadm token create --print-join-command > /tmp/kubeadm_join_command.sh
'

# ============================================================
# 6. Fetch worker join command
# ============================================================

echo "Fetching worker join command..."

gcloud compute scp $MASTER_NAME:/tmp/kubeadm_join_command.sh ./kubeadm_join_command.sh --zone $ZONE

JOIN_COMMAND=$(cat kubeadm_join_command.sh)

# ============================================================
# 7. Join worker nodes
# ============================================================

for VM in $WORKER1_NAME $WORKER2_NAME
do
    echo "Joining $VM to the Kubernetes cluster..."

    gcloud compute ssh $VM --zone $ZONE --command="
        set -e
        sudo kubeadm reset -f || true
        sudo $JOIN_COMMAND
    "
done

# ============================================================
# 8. Copy kubeconfig from master
# ============================================================

echo "Copying kubeconfig from master node..."

gcloud compute scp $MASTER_NAME:~/.kube/config ./kubeconfig --zone $ZONE

export KUBECONFIG=$(pwd)/kubeconfig

# ============================================================
# 9. Verify cluster
# ============================================================

echo "Verifying Kubernetes cluster..."

kubectl get nodes
kubectl get pods -A

# ============================================================
# 10. Deploy application using existing vm-v6 image
# ============================================================

echo "Updating deployment.yaml to use existing image..."

sed -i.bak "s|image: .*|image: ${AR_PATH}|g" deployment.yaml

echo "Applying Kubernetes manifests..."

kubectl apply -f deployment.yaml

# ============================================================
# 11. Final status
# ============================================================

echo "Final Kubernetes status:"

kubectl get pods -o wide
kubectl get svc

echo "Deployment complete."
echo "The application uses existing image:"
echo "$AR_PATH"
echo "Access FastAPI docs through:"
echo "http://<VM_PUBLIC_IP>:30080/docs"