#!/bin/bash
set -euo pipefail

# ============================================================
# Step 4 - Configure self-managed Kubernetes cluster with Ansible
# ============================================================
# This script configures the 3 VMs created by Terraform:
#   - 1 master node
#   - 2 worker nodes
#
# It runs the following Ansible playbooks:
#   1_users.yml
#   2_install_k8s.yml
#   3_create_master.yml
#   4_join_worker.yml
#
# This step does NOT use GKE.
# This step does NOT build or push Docker images.
# This step only creates the self-managed Kubernetes cluster.

PROJECT_ID="composed-card-490512-r1"
ZONE="australia-southeast1-a"

MASTER_NAME="k8s-master"
WORKER1_NAME="k8s-worker-1"
WORKER2_NAME="k8s-worker-2"

# The controller VM user.
# On your current VM this should usually be kzha0139.
SSH_USER="$(whoami)"

echo "Step 4 - Configure self-managed Kubernetes cluster"

# ------------------------------------------------------------
# 1. Make sure Ansible is available
# ------------------------------------------------------------

# If Ansible was installed by install_tools.sh, it should be inside ~/ansible-venv.
if [ -d "$HOME/ansible-venv/bin" ]; then
  export PATH="$HOME/ansible-venv/bin:$PATH"
fi

if ! command -v ansible >/dev/null 2>&1; then
  echo "ERROR: ansible command not found."
  echo "Please run ./01_install_tools.sh first."
  exit 1
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ERROR: ansible-playbook command not found."
  echo "Please run ./install_tools.sh first."
  exit 1
fi

echo "Ansible version:"
ansible --version | head -n 1

# ------------------------------------------------------------
# 2. Check required files
# ------------------------------------------------------------

echo "Checking required files..."

REQUIRED_FILES=(
  "hosts.ini"
  "1_users.yml"
  "2_install_k8s.yml"
  "3_create_master.yml"
  "4_join_worker.yml"
)

for FILE in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "ERROR: Required file not found: $FILE"
    exit 1
  fi
done

echo "All required files found."

# ------------------------------------------------------------
# 3. Read IP addresses from hosts.ini
# ------------------------------------------------------------

MASTER_IP=$(awk '/\[masters\]/{getline; print}' hosts.ini)
WORKER_1_IP=$(awk '/\[workers\]/{getline; print}' hosts.ini)
WORKER_2_IP=$(awk '/\[workers\]/{getline; getline; print}' hosts.ini)

if [ -z "$MASTER_IP" ] || [ -z "$WORKER_1_IP" ] || [ -z "$WORKER_2_IP" ]; then
  echo "ERROR: Could not read master/worker IPs from hosts.ini."
  cat hosts.ini
  exit 1
fi

echo "Master IP: $MASTER_IP"
echo "Worker 1 IP: $WORKER_1_IP"
echo "Worker 2 IP: $WORKER_2_IP"

# ------------------------------------------------------------
# 4. Prepare SSH access with gcloud
# ------------------------------------------------------------
# gcloud compute ssh creates/updates SSH metadata for the current user.
# This makes Ansible SSH access more reliable.

echo "Preparing SSH access using gcloud..."

for VM in "$MASTER_NAME" "$WORKER1_NAME" "$WORKER2_NAME"; do
  echo "Testing SSH access to $VM..."

  gcloud compute ssh "$VM" \
    --zone "$ZONE" \
    --project "$PROJECT_ID" \
    --quiet \
    --command "echo SSH to $VM is ready"
done

# ------------------------------------------------------------
# 5. Select SSH key for Ansible
# ------------------------------------------------------------
# gcloud usually uses ~/.ssh/google_compute_engine.
# install_tools.sh may also generate ~/.ssh/id_ed25519.

if [ -f "$HOME/.ssh/google_compute_engine" ]; then
  SSH_KEY="$HOME/.ssh/google_compute_engine"
elif [ -f "$HOME/.ssh/id_ed25519" ]; then
  SSH_KEY="$HOME/.ssh/id_ed25519"
else
  echo "ERROR: No SSH private key found."
  echo "Expected either:"
  echo "  $HOME/.ssh/google_compute_engine"
  echo "  $HOME/.ssh/id_ed25519"
  exit 1
fi

chmod 600 "$SSH_KEY"

echo "Using SSH user: $SSH_USER"
echo "Using SSH key: $SSH_KEY"

# ------------------------------------------------------------
# 6. Generate Ansible inventory file
# ------------------------------------------------------------
# This creates a richer inventory file from Terraform-generated hosts.ini.

echo "Generating ansible_hosts.ini..."

cat > ansible_hosts.ini <<EOF
[masters]
$MASTER_NAME ansible_host=$MASTER_IP

[workers]
$WORKER1_NAME ansible_host=$WORKER_1_IP
$WORKER2_NAME ansible_host=$WORKER_2_IP

[k8s_cluster:children]
masters
workers

[all:vars]
ansible_user=$SSH_USER
ansible_ssh_private_key_file=$SSH_KEY
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

echo "Generated ansible_hosts.ini:"
cat ansible_hosts.ini

# ------------------------------------------------------------
# 7. Test Ansible connectivity
# ------------------------------------------------------------

echo "Testing Ansible connectivity..."

export ANSIBLE_HOST_KEY_CHECKING=False

ansible -i ansible_hosts.ini all -m ping

# ------------------------------------------------------------
# 8. Run Kubernetes setup playbooks
# ------------------------------------------------------------

echo "Running 1_users.yml..."
ansible-playbook -i ansible_hosts.ini 1_users.yml

echo "Running 2_install_k8s.yml..."
ansible-playbook -i ansible_hosts.ini 2_install_k8s.yml

echo "Running 3_create_master.yml..."
ansible-playbook -i ansible_hosts.ini 3_create_master.yml

echo "Running 4_join_worker.yml..."
ansible-playbook -i ansible_hosts.ini 4_join_worker.yml

# ------------------------------------------------------------
# 9. Verify Kubernetes cluster from master node
# ------------------------------------------------------------
# The kubeconfig generated by kubeadm points to the master's internal IP.
# Since the controller VM may not be in the same VPC, verification is run
# on the master node through Ansible instead of running kubectl locally.

echo "Waiting for Kubernetes nodes to become Ready..."

ansible -i ansible_hosts.ini masters -m shell -a \
  "kubectl wait --for=condition=Ready nodes --all --timeout=300s"

echo "Verifying Kubernetes nodes from master node..."

ansible -i ansible_hosts.ini masters -m shell -a \
  "kubectl get nodes -o wide"

echo "Checking Kubernetes system pods from master node..."

ansible -i ansible_hosts.ini masters -m shell -a \
  "kubectl get pods -A"