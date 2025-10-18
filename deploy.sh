#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Open WebUI — Full Environment Deployment Script
# ------------------------------------------------------------------------------
# This script provisions and deploys the entire Open WebUI stack:
#   1. Creates AWS infrastructure via Terraform (VPC + EKS)
#   2. Installs required cluster add-ons (ALB Controller, CSI Driver, Cert-Manager)
#   3. Deploys Ollama (backend) and Open WebUI (frontend) via Helm charts
#
# Designed for: AWS EKS + Terraform + Helm
# Author: Mathangi Phani Babu
################################################################################

# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------
PROJECT_NAME="${PROJECT_NAME:-open-webui}"
CLUSTER_NAME="${CLUSTER_NAME:-open-webui-eks}"
REGION="${REGION:-ap-south-1}"
TERRAFORM_DIR="${TERRAFORM_DIR:-terraform/dev}"
K8S_BASE_DIR="${K8S_BASE_DIR:-k8s/charts}"
HELM_NAMESPACE="${HELM_NAMESPACE:-default}"
DEFAULT_SC_NAME="${DEFAULT_SC_NAME:-gp3-csi}"

# Timing and retries
ALB_WAIT_ATTEMPTS="${ALB_WAIT_ATTEMPTS:-20}"
ALB_WAIT_SLEEP="${ALB_WAIT_SLEEP:-20}"
CLUSTER_READY_ATTEMPTS="${CLUSTER_READY_ATTEMPTS:-20}"
CLUSTER_READY_SLEEP="${CLUSTER_READY_SLEEP:-15}"

log() { printf "\n[%s] %s\n" "$(date +'%H:%M:%S')" "$*"; }
die() { echo "[ERROR] $*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# REQUIREMENTS VALIDATION
# ------------------------------------------------------------------------------
check_requirements() {
  log "Checking local dependencies..."
  local deps=("aws" "terraform" "kubectl" "helm" "jq")
  for cmd in "${deps[@]}"; do
    command -v "$cmd" &>/dev/null || die "Missing required dependency: $cmd"
  done
  log "All required tools detected ✅"
}

# ------------------------------------------------------------------------------
# CLUSTER READINESS CHECK
# ------------------------------------------------------------------------------
wait_for_cluster_ready() {
  log "Waiting for EKS cluster '$CLUSTER_NAME' to reach ACTIVE state..."
  local status

  for i in $(seq 1 "$CLUSTER_READY_ATTEMPTS"); do
    status=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" \
      --query "cluster.status" --output text 2>/dev/null || echo "UNKNOWN")
    if [[ "$status" == "ACTIVE" ]]; then
      log "Cluster is ACTIVE ✅"
      break
    fi
    log "Current status: $status (attempt $i/$CLUSTER_READY_ATTEMPTS)..."
    sleep "$CLUSTER_READY_SLEEP"
  done
  [[ "$status" == "ACTIVE" ]] || die "Cluster did not reach ACTIVE state."

  log "Verifying worker node readiness..."
  for i in $(seq 1 "$CLUSTER_READY_ATTEMPTS"); do
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1 || true
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready' || echo 0)
    if [[ "$READY_NODES" -ge 1 ]]; then
      log "Nodes ready: $READY_NODES ✅"
      return
    fi
    log "No ready nodes yet (attempt $i). Retrying in $CLUSTER_READY_SLEEP s..."
    sleep "$CLUSTER_READY_SLEEP"
  done

  die "No worker nodes became ready. Verify node group or networking."
}

# ------------------------------------------------------------------------------
# ENSURE DEFAULT STORAGE CLASS
# ------------------------------------------------------------------------------
ensure_default_storageclass() {
  log "Ensuring default StorageClass '${DEFAULT_SC_NAME}' exists..."
  if kubectl get storageclass "${DEFAULT_SC_NAME}" >/dev/null 2>&1; then
    log "StorageClass '${DEFAULT_SC_NAME}' already exists."
  else
    log "Creating default StorageClass '${DEFAULT_SC_NAME}'..."
    kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${DEFAULT_SC_NAME}
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
allowVolumeExpansion: true
parameters:
  type: gp3
EOF
  fi
  kubectl patch storageclass "${DEFAULT_SC_NAME}" -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' >/dev/null || true
  log "Current StorageClasses:"
  kubectl get storageclass
}

# ------------------------------------------------------------------------------
# MAIN EXECUTION FLOW
# ------------------------------------------------------------------------------
main() {
  check_requirements

  log "Starting Terraform deployment..."
  pushd "$TERRAFORM_DIR" >/dev/null
  terraform init -upgrade -input=false
  terraform apply -auto-approve
  ALB_IRSA_ROLE_ARN=$(terraform output -raw alb_controller_irsa_role_arn)
  CLUSTER_NAME=$(terraform output -raw cluster_name)
  REGION=$(terraform output -raw region)
  popd >/dev/null

  log "Configuring kubectl access for EKS cluster..."
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

  wait_for_cluster_ready

  # ----------------------------------------------------------------------------
  # EKS ADD-ONS
  # ----------------------------------------------------------------------------
  log "Installing EKS add-ons (ALB Controller, EBS CSI, Cert-Manager)..."

  helm repo add eks https://aws.github.io/eks-charts >/dev/null || true
  helm repo add jetstack https://charts.jetstack.io >/dev/null || true
  helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver >/dev/null || true
  helm repo update >/dev/null

  # Create ALB Controller Service Account
  kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${ALB_IRSA_ROLE_ARN}
EOF

  log "Installing AWS Load Balancer Controller..."
  kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master" >/dev/null 2>&1 || true

  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName="$CLUSTER_NAME" \
    --set region="$REGION" \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --wait

  log "Installing cert-manager..."
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true \
    --wait

  log "Installing AWS EBS CSI driver..."
  helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.volumeModificationFeature.enabled=true \
    --wait

  ensure_default_storageclass

  log "✅ Cluster add-ons installed successfully."

  # ----------------------------------------------------------------------------
  # APPLICATION DEPLOYMENTS
  # ----------------------------------------------------------------------------
  log "Deploying Ollama backend..."
  kubectl create namespace "$HELM_NAMESPACE" >/dev/null 2>&1 || true
  helm upgrade --install ollama "${K8S_BASE_DIR}/ollama" -n "$HELM_NAMESPACE" --wait
  kubectl -n "$HELM_NAMESPACE" rollout status statefulset/ollama --timeout 300s

  log "Deploying Open WebUI frontend..."
  helm upgrade --install openwebui "${K8S_BASE_DIR}/ui" -n "$HELM_NAMESPACE" --wait
  kubectl -n "$HELM_NAMESPACE" rollout status deployment/openwebui --timeout 300s

  # ----------------------------------------------------------------------------
  # VERIFY INGRESS / ALB DEPLOYMENT
  # ----------------------------------------------------------------------------
  log "Waiting for ALB ingress to become available..."
  for i in $(seq 1 "$ALB_WAIT_ATTEMPTS"); do
    ALB_URL=$(kubectl get ingress -n "$HELM_NAMESPACE" -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
    if [[ -n "$ALB_URL" ]]; then
      echo -e "\n=========================================="
      echo "🎉 Deployment Complete!"
      echo "✅ EKS Cluster: $CLUSTER_NAME"
      echo "🌍 ALB URL: http://$ALB_URL"
      echo "=========================================="
      exit 0
    fi
    log "ALB not ready (attempt $i/$ALB_WAIT_ATTEMPTS)... waiting $ALB_WAIT_SLEEP s."
    sleep "$ALB_WAIT_SLEEP"
  done

  die "ALB did not become ready. Check the ingress and ALB controller logs."
}

main "$@"
