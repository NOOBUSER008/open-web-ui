################################################################################
# Input Variables for EKS Module
# ------------------------------------------------------------------------------
# This file defines all configurable parameters required by the EKS module.
################################################################################

# ------------------------------------------------------------------------------
# Core Network Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be provisioned."
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs used for EKS worker nodes and internal traffic."
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs for exposing public-facing endpoints (ALB, ingress)."
  type        = list(string)
}

# ------------------------------------------------------------------------------
# Cluster Configuration
# ------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Unique name for the EKS cluster. Used across tagging and resource naming."
  type        = string
  default     = "open-webui-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster. Pinning version helps ensure compatibility."
  type        = string
  default     = "1.33"
}

# ------------------------------------------------------------------------------
# Regional Configuration
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region in which the EKS cluster will be deployed."
  type        = string
}
