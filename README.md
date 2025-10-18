# 🚀 Open WebUI + Ollama Cloud Deployment (E2E on AWS EKS)

This project demonstrates a **production-grade deployment** of [Open WebUI](https://github.com/open-webui/open-webui) connected to **Ollama** (running a lightweight LLM such as gemma) on a **Kubernetes cluster** provisioned via **Terraform** on **AWS EKS**.

The solution showcases **DevOps automation**, **modular Helm-based deployment**, and **end-to-end orchestration** using a single command (`deploy.sh`).

---

## 🧠 Objective

Deploy Open WebUI (frontend) connected to Ollama (backend LLM runtime) on an AWS EKS cluster, ensuring full end-to-end functionality, public accessibility, and automated provisioning and cleanup.

---

## 🏗️ Architecture Overview


                           ┌────────────────────────────┐
                           │        AWS Cloud           │
                           │        (EKS Cluster)       │
                           │                            │
      Internet ───────────▶│  +----------------------+  |
                           │  |  AWS ALB (Ingress)   |  │
                           │  +----------------------+  │
                           │             │              │
                           │             ▼              │
                           │   +-------------------+    │
                           │   |   Open WebUI      |    │
                           │   |  (Frontend Pod)   |    │
                           │   +-------------------+    │
                           │             │ service      │
                           │   Internal  ▼              │
                           │   +-------------------+    │
                           │   |     Ollama        |    │
                           │   | (LLM Backend Pod) |    │
                           │   +-------------------+    │
                           │                            │
                           └────────────────────────────┘

# 🚀 User Connectivity Flow:

Ingress (AWS ALB) → exposes Open WebUI to the internet

Open WebUI Pod → provides the chat interface

Ollama Pod → serves LLM inference (e.g., gemma or Llama )

EBS CSI driver → persistent model storage for Ollama

Terraform → provisions all infra (VPC, EKS, IAM roles)


# 🧩 Repository Structure


                open-web-ui/
                ├── terraform/
                │   ├── modules/
                │   │   ├── vpc/
                │   │   └── eks/
                │   └── dev/
                │       ├── main.tf
                │       ├── variables.tf
                │       ├── outputs.tf
                │       ├── provider.tf
                │       └── terraform.tfvars
                │
                ├── k8s/
                │   └── charts/
                │       ├── ollama/
                │       │   ├── Chart.yaml
                │       │   ├── values.yaml
                │       │   └── templates/
                │       │       ├── _helpers.tpl
                │       │       ├── deployment.yaml
                │       │       ├── pvc.yaml
                │       │       └── service.yaml
                │       └── ui/
                │           ├── Chart.yaml
                │           ├── values.yaml
                │           └── templates/
                │               ├── _helpers.tpl
                │               ├── deployment.yaml
                │               ├── service.yaml
                │               └── ingress.yaml
                │
                ├── deploy.sh
                ├── cleanup.sh
                └── README.md


# ⚙️ Tools & Technologies Used

-------------------------------------------------------------
| Category                    | Tool / Service               |
| --------------------------- | ---------------------------- |
| **Cloud Provider**          | AWS                          |
| **IaC**                     | Terraform                    |
| **Container Orchestration** | Amazon EKS (Kubernetes)      |
| **App Deployment**          | Helm (modular charts)        |
| **Ingress Management**      | AWS Load Balancer Controller |
| **TLS Certificates**        | cert-manager                 |
| **Storage Driver**          | AWS EBS CSI Driver           |
| **Automation**              | Bash (deploy.sh, cleanup.sh) |
| **LLM Runtime**             | Ollama                       |
| **Frontend**                | Open WebUI                   |
--------------------------------------------------------------

# 🚀 Deployment Guide 

# 1️⃣ Prerequisites

Ensure the following tools are installed and configured:

Terraform

AWS CLI

kubectl

Helm

AWS IAM user/role with admin access

Default AWS region set (aws configure)


# 2️⃣ Deploy Everything

Run this command from the project root:

./deploy.sh


The script will:

✅ Provision the EKS cluster via Terraform
✅ Configure kubectl
✅ Install ALB Controller, cert-manager, and EBS CSI Driver
✅ Deploy Ollama backend and Open WebUI frontend
✅ Fetch and display the ALB DNS URL automatically

Example output:

🎉 Deployment Successful!
✅ EKS Cluster: open-webui-eks
🌍 Public ALB URL: http://k8s-openwebui-alb-1234567890.ap-south-1.elb.amazonaws.com


Visit the URL in your browser to access Open WebUI 🎨

It’ll be connected to Ollama (running your LLM) inside the cluster.

# 3️⃣ Verify Deployment

Check everything’s running:

kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A


Expected output:

kubectl get pods -A

---------------------------------------------------------------------------------------
| **NAMESPACE** | **NAME**                          | **READY** | **STATUS** | **AGE** |
| ------------- | --------------------------------- | --------- | ---------- | ------- |
| default       | ollama-deployment-xxxx            | 1/1       | Running    | 2m      |
| default       | openwebui-deployment-xxxx         | 1/1       | Running    | 2m      |
| kube-system   | aws-load-balancer-controller-xxxx | 1/1       | Running    | 3m      |
| cert-manager  | cert-manager-xxxx                 | 1/1       | Running    | 2m      |
----------------------------------------------------------------------------------------

kubectl get svc -A

-----------------------------------------------------------------------------------------------------
| **NAMESPACE** | **NAME**  | **TYPE**  | **CLUSTER-IP** | **EXTERNAL-IP** | **PORT(S)**   | **AGE** |
| ------------- | --------- | --------- | -------------- | --------------- | ------------- | ------- |
| default       | ollama    | ClusterIP | 10.0.0.123     | <none>          | 11434/TCP     | 2m      |
| default       | openwebui | ClusterIP | 10.0.0.124     | <none>          | 8080/TCP      | 2m      |
| kube-system   | kube-dns  | ClusterIP | 10.0.0.10      | <none>          | 53/UDP,53/TCP | 3m      |
------------------------------------------------------------------------------------------------------

kubectl get ingress -A
----------------------------------------------------------------------------------------------------------------------------------------------
| **NAMESPACE** | **NAME**          | **CLASS** | **HOSTS** | **ADDRESS (ALB URL)**                                     | **PORTS** | **AGE** |
| ------------- | ----------------- | --------- | --------- | --------------------------------------------------------- | --------- | ------- |
| default       | openwebui-ingress | alb       | *         | k8s-openwebui-alb-1234567890.ap-south-1.elb.amazonaws.com | 80        | 1m      |
-----------------------------------------------------------------------------------------------------------------------------------------------

# 4️⃣ Clean Up Everything

To destroy all resources safely:

./cleanup.sh


This will:

Uninstall Helm releases (ollama, openwebui, and controllers)

Delete leftover Kubernetes resources

Destroy Terraform infra (VPC, EKS, IAM roles, subnets)

Example:

🎯 Cleanup completed for project: open-webui
All resources have been safely deleted.


# 🧠 Design Choices & Rationale

--------------------------------------------------------------------------------------------------------------------------------
| Decision                                           | Justification                                                            |
| -------------------------------------------------- | ------------------------------------------------------------------------ |
| **Modular Helm charts**                            | Easier to manage microservices (Ollama & WebUI independently)            |
| **Terraform + Helm separation**                    | Aligns with IaC best practices (infra separate from workloads)           |
| **Automation scripts (`deploy.sh`, `cleanup.sh`)** | Enables reproducible, end-to-end lifecycle management                    |
| **AWS-managed controllers**                        | Reduces maintenance overhead; ensures native ALB & storage compatibility |
| **No external DB**                                 | Open WebUI stores metadata locally; Ollama model persistence via PVC     |
| **Region: `ap-south-1`**                           | Reliable region for testing                                              |
---------------------------------------------------------------------------------------------------------------------------------


### 🪲 Debugging & Fixes

- **ALB readiness delay:** Added retry logic in `deploy.sh` to wait for ingress hostname availability, ensuring stable ALB provisioning.  
- **EBS StorageClass issue:** Ensured `gp3-csi` is dynamically created and marked as the default StorageClass to support persistent volumes.  
- **Ollama lightweight model:** Used `gemma:2b` instead of heavier Llama 2 to optimize for faster startup and lower resource utilization.  
- **Namespace consistency:** Parameterized Helm templates to dynamically resolve internal service DNS (`{{ .Release.Name }}-ollama`) across environments.  
- **Ollama pod resource issue:** Initially, the medium-sized node group caused the Ollama pod to remain in `ContainerCreating` due to insufficient resources. Switching to the lightweight gemma model resolved the issue.  
- **ALB controller IAM policy:** Encountered failures while creating the ALB because the controller was missing required JSON-based IAM permissions. Added the custom IAM policy (`AWSLoadBalancerControllerIAMPolicy`) via Terraform to fix it.  
- **ALB 400 error during ingress creation:** Faced a 400 response from AWS Load Balancer Controller while provisioning ALB. After investigation and support from AWS, identified and resolved the issue
- **Subnet tagging issue:** Initially, subnets were not properly tagged for EKS discovery (`kubernetes.io/role/elb` / `kubernetes.io/role/internal-elb`). Fixed by adding correct tags in the Terraform VPC module.



# 🧾 Author

Mathangi Phani Babu
DevOps Engineer | AWS | Azure | Terraform | Kubernetes | CI/CD Automation

# 🏁 Summary

This project demonstrates:

End-to-end DevOps automation

Clean modular deployment with Helm and Terraform

Real-world EKS + ALB setup

Best practices in infrastructure lifecycle management

🔥 A single command (./deploy.sh) spins up an entire LLM-powered web app — infra to UI — and ./cleanup.sh resets it.
