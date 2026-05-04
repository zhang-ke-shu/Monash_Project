# FIT5225 Assignment 1 - CloudEco

## Project Overview

This project deploys a FastAPI-based YOLO wildlife detection service on a self-managed Kubernetes cluster on GCP.

Main technologies used:

* FastAPI
* Ultralytics YOLO
* Docker
* Terraform
* Ansible
* Kubernetes
* Locust

Cluster structure(Ubuntu 22.04 LTS):

* 1 controller VM
* 1 Kubernetes master node
* 2 Kubernetes worker nodes

The application image is stored in Google Artifact Registry and exposed through a Kubernetes NodePort service.

## Main Files

* `main.py` - FastAPI application
* `requirements.txt` - Python dependencies
* `Dockerfile` - Docker build file
* `main.tf` - Terraform infrastructure definition
* `deployment.yaml` - Kubernetes Deployment and Service manifest
* `locustfile.py` - Locust load-testing script

Scripts:

* `01_install_tools.sh` - install required tools on the controller VM
* `02_auth_gcp.sh` - authenticate and configure GCP
* `0X_build_push_images.sh` - build and push Docker image
* `03_provision_infra.sh` - provision infrastructure with Terraform
* `04_configure_k8s_cluster.sh` - configure Kubernetes cluster with Ansible
* `05_deploy_app.sh` - deploy application to Kubernetes

Ansible playbooks:

* `1_users.yml`
* `2_install_k8s.yml`
* `3_create_master.yml`
* `4_join_worker.yml`

## Prerequisites

Before running the project, make sure you have:

* a GCP project
* a controller VM
* permission to use Compute Engine and Artifact Registry
* browser access for GCP login

Region and zone used in this project:

* Region: `australia-southeast1`
* Zone: `australia-southeast1-a`

## Step 1 - Copy project files to the controller VM

From your local machine, copy the project folder to the controller VM:

```bash
gcloud compute scp --recurse <folder_location> kzha0139@<controller-vm-name>:~ --zone australia-southeast1-a
```

You can also copy a single file if needed:

```bash
gcloud compute scp <file_location> kzha0139@<controller-vm-name>:~/5225/ --zone australia-southeast1-a
```

Then SSH into the controller VM:

```bash
gcloud compute ssh <controller-vm-name> --zone australia-southeast1-a
```

## Step 2 - Install required tools

Go to the project directory and run:

```bash
cd ~/5225
chmod +x 01_install_tools.sh
./01_install_tools.sh
```

Then activate the Ansible virtual environment:

```bash
cd
source ansible-venv/bin/activate
cd 5225
```

This step installs:

* Terraform
* Google Cloud CLI
* kubectl
* Ansible
* jq
* SSH tools
* Python venv tools

## Step 3 - Authenticate with GCP

Run:

```bash
gcloud auth login
gcloud auth application-default login
```

If needed, set the account explicitly:

```bash
gcloud config set account <account>
```

Then run:

```bash
chmod +x 02_auth_gcp.sh
./02_auth_gcp.sh
```

This step:

* checks active login
* checks Application Default Credentials
* sets the project
* configures Docker authentication for Artifact Registry

## Step 4 - Build and push the Docker image

Run:

```bash
chmod +x 0X_build_push_images.sh
./0X_build_push_images.sh
```

This script builds the Docker image locally and pushes it to Google Artifact Registry.

## Step 5 - Provision infrastructure

Run:

```bash
chmod +x 03_provision_infra.sh
./03_provision_infra.sh
```

This step provisions:

* 1 master VM
* 2 worker VMs

It also generates `hosts.ini` for Ansible.

## Step 6 - Configure the self-managed Kubernetes cluster

Run:

```bash
chmod +x 04_configure_k8s_cluster.sh
./04_configure_k8s_cluster.sh
```

This step uses Ansible to:

* prepare users and sudo access
* install containerd, kubeadm, kubelet, and kubectl
* initialise the master node
* install Calico CNI
* join the worker nodes to the cluster

To verify the cluster:

```bash
ansible -i ansible_hosts.ini masters -m shell -a "kubectl get pods -A"
```

You can also SSH into the master node:

```bash
gcloud compute ssh k8s-master --zone australia-southeast1-a
```

Then check the cluster manually:

```bash
kubectl get pods -A -o wide
kubectl get pods
```

## Step 7 - Deploy the application

Run:

```bash
chmod +x 05_deploy_app.sh
./05_deploy_app.sh
```

This step:

* creates the Artifact Registry image pull secret
* applies `deployment.yaml`
* sets the correct image
* patches the deployment with `imagePullSecrets`
* restarts and verifies the deployment

To verify deployment status:

```bash
ansible -i ansible_hosts.ini masters -m shell -a "kubectl get pods -A"
```

## Step 8 - Scale the application

To scale from the master node:

```bash
kubectl scale deployment wildlife-api-deployment --replicas=x
```

Or from the controller VM:

```bash
ansible -i ansible_hosts.ini masters -m shell -a "kubectl scale deployment wildlife-api-deployment --replicas=x"
```

For benchmarking, test with:

* 1 pod
* 2 pods
* 4 pods
* 8 pods

Examples:

```bash
kubectl scale deployment wildlife-api-deployment --replicas=2
kubectl scale deployment wildlife-api-deployment --replicas=4
kubectl scale deployment wildlife-api-deployment --replicas=8
```

## Step 9 - Access the application

The service is exposed using NodePort `30080`.

Example URL:

```bash
http://<worker-ip>:30080/docs
```

Replace `<worker-ip>` with the public IP of either worker node.

To SSH into worker nodes:

```bash
gcloud compute ssh k8s-worker-1 --zone australia-southeast1-a
gcloud compute ssh k8s-worker-2 --zone australia-southeast1-a
```

## Step 10 - Run Locust load testing

From the controller VM, run:

```bash
locust -f locustfile.py --host=http://<worker-ip>:30080
```

Then open the Locust web UI in the browser and test different user levels under:

* 1 pod
* 2 pods
* 4 pods
* 8 pods

## API Endpoints

### 1. Predict endpoint

`POST /api/predict`

Request body:

```json
{
  "uuid": "example-uuid",
  "image": "<base64-encoded-image>"
}
```

Response fields:

* `uuid`
* `count`
* `detections`
* `boxes`
* `speed_preprocess_ms`
* `speed_inference_ms`
* `speed_postprocess_ms`

### 2. Annotate endpoint

`POST /api/annotate`

Request body:

```json
{
  "uuid": "example-uuid",
  "image": "<base64-encoded-image>"
}
```

Response fields:

* `uuid`
* `image` (base64-encoded annotated image)

## Notes

* This project uses a self-managed Kubernetes cluster, not GKE.
* The Docker image is stored in Google Artifact Registry, not Docker Hub.
* The application is exposed using a NodePort service.
* Each pod is restricted to 1 vCPU as required by the assignment.
* Locust is used for benchmarking under multiple pod configurations.

## Cleanup

After submission or demo, stop or delete cloud resources to avoid unnecessary charges.
```bash
terraform destroy
```
