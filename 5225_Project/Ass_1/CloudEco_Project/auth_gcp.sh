#!/bin/bash
set -euo pipefail

PROJECT_ID="composed-card-490512-r1"
REGION="australia-southeast1"

echo "Step 2 - GCP authentication and configuration"

echo "Checking active gcloud account..."

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
  echo "No active gcloud account found."
  echo "Starting browser-based login..."
  gcloud auth login
else
  echo "Active gcloud account found:"
  gcloud auth list --filter=status:ACTIVE --format="value(account)"
fi

echo "Checking Application Default Credentials for Terraform..."

if [ ! -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
  echo "No Application Default Credentials found."
  echo "Starting ADC login..."
  gcloud auth application-default login
else
  echo "Application Default Credentials already exist."
fi

echo "Setting GCP project..."
gcloud config set project "$PROJECT_ID"

echo "Configuring Docker authentication for Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "Verifying authentication..."
gcloud config list
gcloud auth list

echo "Step 2 complete."
echo "Next step: run Terraform provisioning script."