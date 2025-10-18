#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Cleanup Script — Open WebUI Environment
# ------------------------------------------------------------------------------
# This script safely removes all components deployed via deploy.sh:
#   - Helm releases (Ollama, Open WebUI, Add-ons)
#   - Kubernetes resources (Ingress, PVCs, etc.)
#   - Terraform-managed infrastructure (EKS, VPC, etc.)
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
HELM_NAMESPACE="${HELM_NAMESPACE:-default}"

# ------------------------------------------------------------------------------
# LOGGING UTILITIES
# ------------------------------------------------------------------------------
log() { printf "\n[%s] %s\n" "$(date +'%H:%M:%S')" "$*"; }
warn() { printf "\n[WARN ] %s\n" "$*" >&2; }
error() { printf "\n[ERROR] %s\n" "$*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# CLEANUP BANNER
# ------------------------------------------------------------------------------
echo "=========================================="
echo "🧹 Starting cleanup for: $PROJECT_NAME"
echo "=========================================="

# ------------------------------------------------------------------------------
# STEP 1. Verify Dependencies
# ------------------------------------------------------------------------------
log "Verifying CLI dependencies..."
for tool in aws kubectl helm terraform; do
  if ! command -v "$tool" &>/dev/null; then
    error "Missing required tool: $tool. Please install it before running cleanup."
  fi
done
log "✅ All required tools available."

# ------------------------------------------------------------------------------
# STEP 2. Check Cluster Existence
# ------------------------------------------------------------------------------
log "Checking if EKS cluster '$CLUSTER_NAME' exists..."
if aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  log "Cluster found. Updating kubeconfig context..."
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" >/dev/null
else
  warn "Cluster not found. Skipping kubectl context setup."
fi

# ------------------------------------------------------------------------------
# STEP 3. Uninstall Helm Releases (App + Add-ons)
# ------------------------------------------------------------------------------
log "Uninstalling Helm releases..."
set +e
helm uninstall openwebui -n "$HELM_NAMESPACE" >/dev/null 2>&1 && log "✅ Removed: openwebui" || warn "ℹ️ Skipped: openwebui"
helm uninstall ollama -n "$HELM_NAMESPACE" >/dev/null 2>&1 && log "✅ Removed: ollama" || warn "ℹ️ Skipped: ollama"
helm uninstall aws-load-balancer-controller -n kube-system >/dev/null 2>&1 && log "✅ Removed: AWS Load Balancer Controller"
helm uninstall aws-ebs-csi-driver -n kube-system >/dev/null 2>&1 && log "✅ Removed: AWS EBS CSI Driver"
helm uninstall cert-manager -n cert-manager >/dev/null 2>&1 && log "✅ Removed: cert-manager"
set -e

# ------------------------------------------------------------------------------
# STEP 4. Cleanup Residual Kubernetes Resources
# ------------------------------------------------------------------------------
log "Cleaning up leftover Kubernetes resources..."
kubectl delete ingress --all -A --ignore-not-found=true
kubectl delete pvc --all -A --ignore-not-found=true
kubectl delete svc --all -A --ignore-not-found=true
kubectl delete deployment --all -A --ignore-not-found=true
kubectl delete pods --all -A --ignore-not-found=true
log "✅ All Kubernetes resources deleted."

# ------------------------------------------------------------------------------
# STEP 5. Destroy Terraform Infrastructure
# ------------------------------------------------------------------------------
if [[ -d "$TERRAFORM_DIR" ]]; then
  log "Destroying Terraform-managed infrastructure..."
  pushd "$TERRAFORM_DIR" >/dev/null
  terraform init -input=false -upgrade >/dev/null 2>&1
  terraform destroy -auto-approve -input=false
  popd >/dev/null
  log "✅ Terraform infrastructure destroyed."
else
  warn "Terraform directory '$TERRAFORM_DIR' not found — skipping infrastructure destroy."
fi

# ------------------------------------------------------------------------------
# STEP 6. Final Verification
# ------------------------------------------------------------------------------
log "Verifying post-cleanup state..."
if aws eks describe-cluster --region "$REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  warn "⚠️ EKS cluster still exists. You may need to delete it manually via AWS Console."
else
  log "✅ EKS cluster successfully removed."
fi

# ------------------------------------------------------------------------------
# COMPLETION
# ------------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "🎯 Cleanup completed successfully!"
echo "Project: $PROJECT_NAME"
echo "Region: $REGION"
echo "=========================================="
