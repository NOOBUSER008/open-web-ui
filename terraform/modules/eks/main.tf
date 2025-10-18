################################################################################
# Retrieve Current AWS Identity
# ------------------------------------------------------------------------------
# Used to dynamically grant the current Terraform user administrative access
# to the EKS cluster via access entries. This ensures that whoever runs the 
# Terraform apply command can manage the cluster post-deployment.
################################################################################
data "aws_caller_identity" "current" {}

################################################################################
# EKS Cluster Creation
# ------------------------------------------------------------------------------
# Using the official terraform-aws-modules/eks module for lifecycle management.
# This module abstracts away complex IAM, networking, and node group logic 
# while maintaining flexibility and best practices alignment with AWS EKS.
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  # Core cluster configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Networking
  vpc_id     = var.vpc_id
  subnet_ids = concat(var.public_subnets, var.private_subnets)

  # Node Group Configuration
  # ----------------------------------------------------------------------------
  # Using managed node groups for simplified updates and auto-scaling.
  # Default configuration aims for high availability and fault tolerance
  # within private subnets (for improved security posture).
  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["m5.2xlarge"]   # Balanced for moderate workload + LLM runtime
      capacity_type  = "SPOT"      # Consider ON_DEMAND in production for non-interruption workloads
      subnet_ids     = var.private_subnets
    }
  }

  # Default policies applied to all node groups
  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      # Enables EBS CSI driver for dynamic volume provisioning (required for PV/PVC)
      ebs_policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  # Authentication Mode
  # ----------------------------------------------------------------------------
  # Allows both API-based IAM access and legacy ConfigMap-based authentication.
  # Ensures compatibility with kubectl access from IAM principals.
  authentication_mode = "API_AND_CONFIG_MAP"

  # Access Entries
  # ----------------------------------------------------------------------------
  # Grants the current Terraform executor (your IAM identity) cluster admin 
  # privileges. Essential for post-deployment cluster management.
  access_entries = {
    current_user = {
      principal_arn = data.aws_caller_identity.current.arn
      access_policies = {
        cluster_admin = {
          policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # IRSA (IAM Roles for Service Accounts)
  # ----------------------------------------------------------------------------
  # Enables fine-grained IAM permissions at the pod level, required for 
  # AWS controllers (like ALB or external-dns) and future workload isolation.
  enable_irsa = true

  # Cluster API Endpoints
  # ----------------------------------------------------------------------------
  # Both private and public access enabled for flexibility. 
  # In production, consider restricting public access to specific IP ranges.
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

################################################################################
# IAM Policy for AWS Load Balancer Controller
# ------------------------------------------------------------------------------
# The AWS Load Balancer Controller manages ALBs and NLBs for Kubernetes Services.
# We’re creating a dedicated IAM policy to give it necessary permissions 
# to provision, modify, and clean up AWS Load Balancer resources.
################################################################################
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Custom policy for AWS ALB Controller to manage LoadBalancers in EKS"
  policy      = file("${path.module}/iam_policy.json")
}

################################################################################
# IAM Role for ALB Controller via IRSA
# ------------------------------------------------------------------------------
# This creates an IAM Role associated with the `aws-load-balancer-controller` 
# service account inside `kube-system` namespace. The role will assume this 
# policy through the OIDC provider from the EKS cluster.
################################################################################
module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "aws-load-balancer-controller"

  # Custom policy attachment (handled separately below)
  attach_load_balancer_controller_policy = false

  # Bind OIDC provider to the IRSA role
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

################################################################################
# Attach Custom Policy to IRSA Role
# ------------------------------------------------------------------------------
# This step links the previously created IAM Policy with the IRSA role 
# to allow the Load Balancer Controller to function correctly.
################################################################################
resource "aws_iam_role_policy_attachment" "alb_controller_attachment" {
  role       = module.alb_controller_irsa.iam_role_name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}
