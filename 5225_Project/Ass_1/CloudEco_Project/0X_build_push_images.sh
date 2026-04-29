#!/bin/bash
set -euo pipefail

# ============================================================
# Step 0X - Build and Push Docker Image to Artifact Registry
# ============================================================
# This script builds the application Docker image locally,
# tags it as vm-v6, and pushes it to Google Artifact Registry.
#
# It is intended as a backup utility script.
# It should NOT be automatically called by the deployment flow.
#
# Expected usage:
#   chmod +x 0X_build_push_images.sh
#   ./0X_build_push_images.sh

# -------------------------------
# Configuration
# -------------------------------
PROJECT_ID="composed-card-490512-r1"
REGION="australia-southeast1"
REPO_NAME="wildlife-repo"
IMAGE_NAME="wildlife-api"
TAG="vm-v6"

LOCAL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
REMOTE_IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}"

# -------------------------------
# Helper functions
# -------------------------------
print_step() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $1"
    exit 1
  fi
}

# -------------------------------
# Check required commands
# -------------------------------
print_step "Checking required commands"

check_command docker
check_command gcloud
check_command grep

echo "All required commands are available."

# -------------------------------
# Check required files
# -------------------------------
print_step "Checking required files"

if [ ! -f "Dockerfile" ]; then
  echo "ERROR: Dockerfile not found in the current directory."
  exit 1
fi

if [ ! -f "requirements.txt" ]; then
  echo "WARNING: requirements.txt not found."
fi

if [ ! -f "main.py" ]; then
  echo "WARNING: main.py not found."
fi

echo "Required build files check completed."

# -------------------------------
# Show image details
# -------------------------------
print_step "Image configuration"

echo "Project ID:        ${PROJECT_ID}"
echo "Region:            ${REGION}"
echo "Repository:        ${REPO_NAME}"
echo "Image name:        ${IMAGE_NAME}"
echo "Tag:               ${TAG}"
echo "Local image:       ${LOCAL_IMAGE_NAME}"
echo "Remote image:      ${REMOTE_IMAGE_NAME}"

# -------------------------------
# Check gcloud authentication
# -------------------------------
print_step "Checking gcloud authentication"

ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n 1 || true)"

if [ -z "${ACTIVE_ACCOUNT}" ]; then
  echo "ERROR: No active gcloud account found."
  echo "Please run: gcloud auth login"
  exit 1
fi

echo "Active gcloud account: ${ACTIVE_ACCOUNT}"

# -------------------------------
# Set active project
# -------------------------------
print_step "Setting GCP project"

gcloud config set project "${PROJECT_ID}" >/dev/null

CURRENT_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"

if [ "${CURRENT_PROJECT}" != "${PROJECT_ID}" ]; then
  echo "ERROR: Failed to set the correct GCP project."
  exit 1
fi

echo "Current project set to: ${CURRENT_PROJECT}"

# -------------------------------
# Configure Docker authentication
# -------------------------------
print_step "Configuring Docker authentication for Artifact Registry"

gcloud auth configure-docker "${REGION}-docker.pkg.dev" -q

echo "Docker authentication configured."

# -------------------------------
# Optional confirmation
# -------------------------------
print_step "Confirmation"

echo "This script will build and push the following image:"
echo "${REMOTE_IMAGE_NAME}"
read -r -p "Continue? (y/n): " CONFIRM

if [ "${CONFIRM}" != "y" ] && [ "${CONFIRM}" != "Y" ]; then
  echo "Operation cancelled."
  exit 0
fi

# -------------------------------
# Build Docker image
# -------------------------------
print_step "Building Docker image"

docker build -t "${LOCAL_IMAGE_NAME}" .

echo "Docker image build completed."

# -------------------------------
# Tag Docker image
# -------------------------------
print_step "Tagging Docker image"

docker tag "${LOCAL_IMAGE_NAME}" "${REMOTE_IMAGE_NAME}"

echo "Docker image tagging completed."

# -------------------------------
# Show local images
# -------------------------------
print_step "Listing matching local Docker images"

docker images | grep "${IMAGE_NAME}" || true

# -------------------------------
# Push Docker image
# -------------------------------
print_step "Pushing Docker image to Artifact Registry"

docker push "${REMOTE_IMAGE_NAME}"

echo "Docker image push completed."

# -------------------------------
# Verify pushed image
# -------------------------------
print_step "Verifying pushed image in Artifact Registry"

gcloud artifacts docker images list \
  "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}" \
  --include-tags | grep "${IMAGE_NAME}" || true

# -------------------------------
# Done
# -------------------------------
print_step "Build and push process completed successfully"

echo "Pushed image:"
echo "${REMOTE_IMAGE_NAME}"