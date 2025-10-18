################################################################################
# VPC Creation Module
# ------------------------------------------------------------------------------
# This module provisions a complete Virtual Private Cloud (VPC) with public and
# private subnets across multiple Availability Zones. It is used as a foundation
# for the EKS cluster and related workloads.
#
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # ----------------------------------------------------------------------------
  # Core Configuration
  # ----------------------------------------------------------------------------
  name = "openwebui-vpc" # Name of the VPC (can be overridden for other env through tfvars)
  cidr = "10.0.0.0/16"  # Primary VPC CIDR range (can be overridden for other environments through tfvars)

  # Availability Zones — spreading across two for high availability
  azs = ["ap-south-1a", "ap-south-1b"]

  # ----------------------------------------------------------------------------
  # Subnet Configuration
  # ----------------------------------------------------------------------------
  # Public subnets are used for load balancers, ingress controllers, or any
  # external-facing component.
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # Private subnets are used for internal workloads (EKS nodes, Ollama, etc.)
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  # ----------------------------------------------------------------------------
  # Network Settings
  # ----------------------------------------------------------------------------
  enable_nat_gateway       = true   # Enables outbound internet for private subnets
  single_nat_gateway       = true   # Keeps cost lower by using a single NAT Gateway
  enable_dns_hostnames     = true   # Required for internal DNS resolution
  enable_dns_support       = true   # Enables DNS support for EC2 and EKS nodes
  map_public_ip_on_launch  = true   # Automatically assigns public IPs to public subnet resources

  # ----------------------------------------------------------------------------
  # Subnet Tagging (Required for EKS Integration)
  # ----------------------------------------------------------------------------
  # EKS relies on subnet tags to discover networking zones for service deployment.
  # Public subnets → ELB / Ingress Controllers
  # Private subnets → Internal Load Balancers, Cluster Nodes
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
  }

  # ----------------------------------------------------------------------------
  # Global Tags
  # ----------------------------------------------------------------------------
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
