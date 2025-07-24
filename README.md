# Migration Guide: From AWS EKS to GKE or Alibaba ACK

This document provides a detailed guide on how to migrate the current infrastructure setup from **Amazon EKS** to **Google Cloud GKE** or **Alibaba Cloud ACK**, focusing on using **modular Terraform infrastructure** and adapting  **Jenkins pipeline**.

---

## Current Setup Overview

The current setup includes:

- A Node.js-based application containerized with Docker.
- A Jenkins CI/CD pipeline that:
  - Builds and pushes Docker images to Docker Hub.
  - Provisions an AWS EKS cluster using Terraform.
  - Deploys Kubernetes manifests to the EKS cluster.
- Credentials managed with Jenkins credentials plugin.
- Terraform infrastructure defined in modular form.

---

## Objective

Migrate this setup to:

- [ ] Google Kubernetes Engine (GKE)
- [ ] Alibaba Cloud ACK (Container Service for Kubernetes)

With the goal of:

- Replacing EKS Terraform modules with GKE or ACK modules.
- Changing Jenkins pipeline stages related to infrastructure provisioning and deployment.
- Keeping everything else (Dockerfile, Kubernetes_manifests, app_files, etc.) the same.

---

## Step 1: Refactor Terraform Modules

### Current AWS EKS Module Structure

```hcl
module "eks" {
  source = "./modules/eks"
  ...
}

---
### New GKE Module (Example)
Create modules/gke/main.tf:

hcl
Copy
Edit
provider "google" {
  project = your-gcp-project-id
  region  = us-central1
}

resource "google_container_cluster" "primary" {
  name     = eyego-cluster
  location = us-central1
  initial_node_count = 1
  ...
}

In main.tf:

hcl
Copy
Edit
module "gke" {
  source       = "./modules/gke"
}

New Alibaba ACK Module (Example)
Create modules/ack/main.tf:

hcl
Copy
Edit
provider "alicloud" {
  region = cn-hangzhou
}

resource "alicloud_cs_managed_kubernetes_cluster" "ack_cluster" {
  name = eyego-cluster
  ...
}
In main.tf:

hcl
Copy
Edit
module "ack" {
  source       = "./modules/ack"
}

 Step 2: Jenkins Pipeline Changes

Replace AWS Credentials with GCP/Alibaba
In your Jenkinsfile, replace the aws-credentials block with credentials suited to the cloud provider:

GKE Example
groovy
Copy
Edit
stage('Create GKE Cluster') {
    steps {
        withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
              terraform init -reconfigure
              terraform apply -auto-approve
            '''
        }
    }
}

Alibaba ACK Example
groovy
Copy
Edit
stage('Create ACK Cluster') {
    steps {
        withCredentials([
            usernamePassword(
              credentialsId: 'alibaba-credentials',
              usernameVariable: 'ALICLOUD_ACCESS_KEY',
              passwordVariable: 'ALICLOUD_SECRET_KEY'
            )
        ]) {
            sh '''
              export ALICLOUD_ACCESS_KEY=$ALICLOUD_ACCESS_KEY
              export ALICLOUD_SECRET_KEY=$ALICLOUD_SECRET_KEY
              terraform init -reconfigure
              terraform apply -auto-approve
            '''
        }
    }
}

Change Deployment Stage
Replace aws eks update-kubeconfig with the appropriate CLI commands:

GKE:
groovy
Copy
Edit
stage('Deploy to GKE') {
    steps {
        withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
            sh '''
              export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
              gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
              gcloud container clusters get-credentials eyego-cluster --region us-central1
              kubectl apply -f k8s/
            '''
        }
    }
}
Alibaba ACK:
groovy
Copy
Edit
stage('Deploy to ACK') {
    steps {
        withCredentials([
          usernamePassword(
            credentialsId: 'alibaba-credentials',
            usernameVariable: 'ALICLOUD_ACCESS_KEY',
            passwordVariable: 'ALICLOUD_SECRET_KEY'
          )
        ]) {
            sh '''
              aliyun configure set --profile eyego --access-key-id $ALICLOUD_ACCESS_KEY --access-key-secret $ALICLOUD_SECRET_KEY --region cn-hangzhou
              aliyun cs DescribeKubernetesClusterConfig --ClusterId $(aliyun cs DescribeClusters | jq -r '.[0].cluster_id') > kubeconfig.yaml
              export KUBECONFIG=$(pwd)/kubeconfig.yaml
              kubectl apply -f k8s/
            '''
        }
    }
}

 Step 3: Update Jenkins Credentials
For GCP:

Create a service account in IAM.

Grant it Kubernetes Engine Admin + Viewer roles.

Generate a JSON key.

Upload it to Jenkins as a “secret file” credential (ID: gcp-service-account).

For Alibaba Cloud:

Use Access Key ID and Secret Access Key.

Store in Jenkins credentials as usernamePassword.

 Resources
Terraform Docs
Terraform GKE Module

Terraform Alibaba ACK Module

CLI Docs
gcloud container clusters get-credentials

aliyun CLI ACK Guide

Jenkins Docs
Jenkins Credentials Plugin

Using Terraform with Jenkins
