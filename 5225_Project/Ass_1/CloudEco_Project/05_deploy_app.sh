#!/bin/bash
set -euo pipefail

# ============================================================
# Step 5 - Deploy FastAPI YOLO application to Kubernetes
# ============================================================
# This script deploys the application to the self-managed K8s cluster.
# It does NOT build, tag, or push Docker images.
# It uses the existing Artifact Registry image:
# wildlife-api:vm-v6
#
# Important:
# This version does NOT edit deployment.yaml structure.
# It applies deployment.yaml first, then uses kubectl patch/set image.
# This avoids YAML indentation or schema errors.

PROJECT_ID="composed-card-490512-r1"
REGION="australia-southeast1"
REPO_NAME="wildlife-repo"
IMAGE_NAME="wildlife-api"
TAG="vm-v6"

IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"
REGISTRY_SERVER="${REGION}-docker.pkg.dev"

SECRET_NAME="artifact-registry-secret"
DEPLOYMENT_NAME="wildlife-api-deployment"
CONTAINER_NAME="wildlife-app"
APP_LABEL="wildlife-api"

SSH_USER="$(whoami)"

echo "Step 5 - Deploy application to Kubernetes"
echo "Using existing image:"
echo "$IMAGE_PATH"

# ------------------------------------------------------------
# 1. Check required files
# ------------------------------------------------------------

if [ ! -f "deployment.yaml" ]; then
  echo "ERROR: deployment.yaml not found."
  exit 1
fi

if [ ! -f "hosts.ini" ]; then
  echo "ERROR: hosts.ini not found."
  echo "Please run Step 3 first."
  exit 1
fi

if [ ! -f "ansible_hosts.ini" ]; then
  echo "ERROR: ansible_hosts.ini not found."
  echo "Please run Step 4 first."
  exit 1
fi

echo "Required files found."

# ------------------------------------------------------------
# 2. Read node public IPs
# ------------------------------------------------------------

MASTER_IP=$(awk '/\[masters\]/{getline; print}' hosts.ini)
WORKER_1_IP=$(awk '/\[workers\]/{getline; print}' hosts.ini)
WORKER_2_IP=$(awk '/\[workers\]/{getline; getline; print}' hosts.ini)

echo "Master IP: $MASTER_IP"
echo "Worker 1 IP: $WORKER_1_IP"
echo "Worker 2 IP: $WORKER_2_IP"

# ------------------------------------------------------------
# 3. Select SSH key
# ------------------------------------------------------------

if [ -f "$HOME/.ssh/google_compute_engine" ]; then
  SSH_KEY="$HOME/.ssh/google_compute_engine"
elif [ -f "$HOME/.ssh/id_ed25519" ]; then
  SSH_KEY="$HOME/.ssh/id_ed25519"
else
  echo "ERROR: No SSH private key found."
  exit 1
fi

chmod 600 "$SSH_KEY"

echo "Using SSH user: $SSH_USER"
echo "Using SSH key: $SSH_KEY"

# ------------------------------------------------------------
# 4. Generate Artifact Registry imagePullSecret YAML
# ------------------------------------------------------------
# Artifact Registry is private.
# This secret allows Kubernetes worker nodes to pull the vm-v6 image.

echo "Generating Artifact Registry image pull secret..."

ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)

if [ -z "$ACTIVE_ACCOUNT" ]; then
  echo "ERROR: No active gcloud account found."
  echo "Please run auth_gcp.sh first."
  exit 1
fi

ACCESS_TOKEN=$(gcloud auth print-access-token)

kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-server="$REGISTRY_SERVER" \
  --docker-username=oauth2accesstoken \
  --docker-password="$ACCESS_TOKEN" \
  --docker-email="$ACTIVE_ACCOUNT" \
  --dry-run=client \
  -o yaml > artifact-registry-secret.yaml

echo "Secret YAML generated."

# ------------------------------------------------------------
# 5. Copy files to master node
# ------------------------------------------------------------

echo "Copying deployment files to master node..."

scp \
  -i "$SSH_KEY" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  deployment.yaml \
  artifact-registry-secret.yaml \
  "$SSH_USER@$MASTER_IP:/home/$SSH_USER/"

# ------------------------------------------------------------
# 6. Apply manifests and patch deployment on master
# ------------------------------------------------------------

echo "Applying secret, deployment, image, and imagePullSecret on master..."

ansible -i ansible_hosts.ini masters -m shell -a "
set -e

kubectl apply -f /home/$SSH_USER/artifact-registry-secret.yaml

kubectl apply -f /home/$SSH_USER/deployment.yaml

kubectl set image deployment/$DEPLOYMENT_NAME \
  $CONTAINER_NAME=$IMAGE_PATH

kubectl patch deployment $DEPLOYMENT_NAME \
  -p '{\"spec\":{\"template\":{\"spec\":{\"imagePullSecrets\":[{\"name\":\"$SECRET_NAME\"}]}}}}'

kubectl rollout restart deployment/$DEPLOYMENT_NAME
"

# ------------------------------------------------------------
# 7. Wait for rollout
# ------------------------------------------------------------

echo "Waiting for deployment rollout..."

ansible -i ansible_hosts.ini masters -m shell -a "
kubectl rollout status deployment/$DEPLOYMENT_NAME --timeout=300s
" || true

echo "Waiting for application pods to become Ready..."

ansible -i ansible_hosts.ini masters -m shell -a "
kubectl wait --for=condition=Ready pod -l app=$APP_LABEL --timeout=300s
" || true

# ------------------------------------------------------------
# 8. Show final status
# ------------------------------------------------------------

echo "Final deployment status:"

ansible -i ansible_hosts.ini masters -m shell -a "kubectl get deployment $DEPLOYMENT_NAME -o wide"
ansible -i ansible_hosts.ini masters -m shell -a "kubectl get pods -l app=$APP_LABEL -o wide"
ansible -i ansible_hosts.ini masters -m shell -a "kubectl get svc -o wide"

echo "Checking imagePullSecrets:"
ansible -i ansible_hosts.ini masters -m shell -a "
kubectl get deployment $DEPLOYMENT_NAME -o yaml | grep -A5 imagePullSecrets
" || true

echo "Checking image:"
ansible -i ansible_hosts.ini masters -m shell -a "
kubectl get deployment $DEPLOYMENT_NAME -o yaml | grep 'image:'
"

# ------------------------------------------------------------
# 9. Print URLs
# ------------------------------------------------------------

echo "Step 5 complete."
echo ""
echo "Use worker NodePort URLs:"
echo "http://$WORKER_1_IP:30080/docs"
echo "http://$WORKER_2_IP:30080/docs"
echo ""
echo "Master URL may not always work depending on NodePort forwarding:"
echo "http://$MASTER_IP:30080/docs"
echo ""
echo "Existing image used:"
echo "$IMAGE_PATH"