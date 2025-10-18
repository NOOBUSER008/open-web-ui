################################################################################
# Output Variables — Dev Environment
# ------------------------------------------------------------------------------
# These outputs provide quick access to EKS configuration details and 
# IAM references for automation and operational workflows.
################################################################################

# ------------------------------------------------------------------------------
# Core Cluster Information
# ------------------------------------------------------------------------------
output "cluster_name" {
  description = "Name of the deployed EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint URL for the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "region" {
  description = "AWS region where the cluster is deployed."
  value       = var.aws_region
}

# ------------------------------------------------------------------------------
# Useful CLI Command
# ------------------------------------------------------------------------------
# Provides the AWS CLI command to update kubeconfig locally for kubectl access.
# Example:
#   terraform output kubeconfig_command | bash
# ------------------------------------------------------------------------------
output "kubeconfig_command" {
  description = "Command to configure kubectl access to the EKS cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# ------------------------------------------------------------------------------
# IAM Role References
# ------------------------------------------------------------------------------
output "alb_controller_irsa_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller via IRSA."
  value       = module.eks.alb_controller_irsa_role_arn
}
