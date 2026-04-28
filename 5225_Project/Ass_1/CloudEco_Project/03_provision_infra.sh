sudo apt install -y netcat-openbsd

#!/bin/bash
set -euo pipefail

PROJECT_ID="composed-card-490512-r1"
ZONE="australia-southeast1-a"

echo "Step 3 - Provision infrastructure with Terraform"

echo "Checking active gcloud account..."
gcloud auth list --filter=status:ACTIVE

echo "Setting project..."
gcloud config set project "$PROJECT_ID"

echo "Running Terraform..."
terraform init
terraform validate
terraform apply -auto-approve

echo "Reading Terraform outputs..."

MASTER_IP=$(terraform output -raw master_external_ip)
WORKER_1_IP=$(terraform output -json worker_external_ips | jq -r '.[0]')
WORKER_2_IP=$(terraform output -json worker_external_ips | jq -r '.[1]')

echo "Master IP: $MASTER_IP"
echo "Worker 1 IP: $WORKER_1_IP"
echo "Worker 2 IP: $WORKER_2_IP"

echo "Generating Ansible inventory hosts.ini..."

cat > hosts.ini <<EOF
[masters]
$MASTER_IP

[workers]
$WORKER_1_IP
$WORKER_2_IP

[k8s_cluster:children]
masters
workers
EOF

echo "hosts.ini generated:"
cat hosts.ini

echo "Waiting for SSH to become available..."

for IP in "$MASTER_IP" "$WORKER_1_IP" "$WORKER_2_IP"
do
  echo "Checking SSH on $IP..."

  until nc -z -w 5 "$IP" 22; do
    echo "Waiting for $IP:22 ..."
    sleep 5
  done

  echo "$IP is reachable by SSH."
done

echo "Step 3 complete."
echo "Next step: install and configure Kubernetes on the 1 master + 2 workers."