################################################################################
# Output Variables for EKS Module
################################################################################

# ------------------------------------------------------------------------------
# EKS Cluster Metadata
# ------------------------------------------------------------------------------

output "cluster_name" {
  description = "Name of the deployed EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Public endpoint for accessing the Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data required for cluster authentication."
  value       = module.eks.cluster_certificate_authority_data
}

# ------------------------------------------------------------------------------
# IAM Role References
# ------------------------------------------------------------------------------

output "alb_controller_irsa_role_arn" {
  description = "ARN of the IAM role associated with the AWS Load Balancer Controller via IRSA."
  value       = module.alb_controller_irsa.iam_role_arn
}
