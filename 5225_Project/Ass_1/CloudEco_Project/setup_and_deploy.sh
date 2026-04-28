#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration Variables ---
PROJECT_ID="composed-card-490512-r1"
REGION="australia-southeast1"
ZONE="australia-southeast1-a"
REPO_NAME="wildlife-repo"
IMAGE_NAME="wildlife-api"
TAG="vm-v6"
CLUSTER_NAME="wildlife-cluster"
AR_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"

echo "Starting Automation Script for FIT5225 Assignment 1..."

# --- 1. System Update & Base Tools ---
# Install essential tools for Docker, Python, and GCP
echo "Installing base tools..."
sudo apt update
sudo apt install -y docker.io git python3-pip python3-venv unzip curl wget gnupg software-properties-common

# --- 2. Google Cloud SDK & GKE Auth Plugin ---
echo "Installing kubectl and GKE auth plugin..."
sudo apt update
sudo apt install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin

# --- 3. Terraform Installation ---
# Setup HashiCorp repository and install Terraform
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
fi
terraform -version

# --- 4. Docker Service Configuration ---
echo "Configuring Docker..."
sudo systemctl start docker
sudo systemctl enable docker
# Note: Adding user to group requires a re-login or 'newgrp docker' to take effect
sudo usermod -aG docker $USER

# --- 5. Project Directory Setup ---
# Adjusting permissions for the project folder
if [ -d "~/5225" ]; then
    sudo chown -R $USER:$USER ~/5225
    cd ~/5225
fi

# --- 6. Non-Interactive GCP Authentication ---
# Using a service account key file to skip browser authentication [cite: 10, 11]
echo "Authenticating using service account key..."

KEY_FILE="gcp-key.json"

if [ -f "$KEY_FILE" ]; then
    # Authenticate gcloud CLI
    gcloud auth activate-service-account --key-file="$KEY_FILE" 
    
    # Authenticate Application Default Credentials (ADC) for Terraform
    export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/"$KEY_FILE" 
    
    # Configure Docker authentication
    gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet [cite: 12]
    
    gcloud config set project $PROJECT_ID [cite: 12]
else
    echo "ERROR: $KEY_FILE not found. Please upload the service account key."
    exit 1
fi

# --- 7. Infrastructure as Code (IaC) ---
# Professional-grade IaC lifecycle 
echo "Running Terraform..."
terraform init
terraform validate
terraform apply -auto-approve

# --- 8. Kubernetes Cluster Connection ---
echo "Fetching GKE credentials..."
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# Verify nodes are ready [cite: 133]
kubectl get nodes

# --- 9. Docker Build & Push ---
# Packaging the Python application into an optimized image [cite: 38, 91]
echo "Building and pushing Docker image..."
docker build -t $IMAGE_NAME:$TAG .
docker tag $IMAGE_NAME:$TAG $AR_PATH
docker push $AR_PATH

# --- 10. Kubernetes Deployment ---
# Deploying to K8s with resource limits [cite: 11, 41]
echo "Applying Kubernetes manifests..."
kubectl apply -f deployment.yaml

# Wait for External IP to be assigned
echo "Waiting for LoadBalancer IP..."
sleep 20
kubectl get svc

# --- 11. Performance Testing Setup ---
echo "Setting up Locust for benchmarking..."
python3 -m venv venv
source venv/bin/activate
pip install locust
echo "Locust is ready. Run 'locust -f locustfile.py --host=http://EXTERNAL-IP' to start testing[cite: 112, 119]."

echo "Automation process complete."