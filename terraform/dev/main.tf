################################################################################
# Open WebUI — Development Environment Infrastructure
# ------------------------------------------------------------------------------
# This root Terraform configuration wires together reusable infrastructure 
# modules (VPC + EKS) to deploy a dedicated Kubernetes environment for Open WebUI.
#
# Environment: Development (ap-south-1)
# Author: Mathangi Phani Babu
################################################################################

# ------------------------------------------------------------------------------
# Networking Layer
# ------------------------------------------------------------------------------
# The VPC module provisions core networking components including subnets,
# route tables, NAT gateways, and DNS settings.
# Serves as the foundational layer for the EKS cluster.
# ------------------------------------------------------------------------------
module "vpc" {
  source = "../modules/vpc"
}

# ------------------------------------------------------------------------------
# Compute & Orchestration Layer (EKS)
# ------------------------------------------------------------------------------
# The EKS module creates the Kubernetes control plane, managed node groups,
# and supporting IAM roles (including IRSA for the ALB controller).
# ------------------------------------------------------------------------------
module "eks" {
  source = "../modules/eks"

  # Input Variables
  cluster_name    = var.cluster_name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  aws_region      = var.aws_region
}
