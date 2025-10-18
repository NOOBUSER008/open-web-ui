################################################################################
# Output Variables for VPC Module
# ------------------------------------------------------------------------------
# Exposes key network identifiers for downstream modules (EKS, Bastion, etc.).
# These outputs allow inter-module communication without hardcoding values.
################################################################################

output "vpc_id" {
  description = "Unique identifier of the created VPC."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs created within the VPC."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs created within the VPC."
  value       = module.vpc.public_subnets
}
