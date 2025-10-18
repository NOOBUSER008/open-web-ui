################################################################################
# Input Variables for VPC Module
# ------------------------------------------------------------------------------
# Defines configurable network parameters used to provision the base VPC.
# Each variable includes practical descriptions for team readability.
################################################################################

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC (defines overall IP address space)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "project_name" {
  description = "Project name used for tagging and resource identification."
  type        = string
  default     = "open-webui"
}

variable "az_count" {
  description = "Number of availability zones to distribute resources across (usually 2–3)."
  type        = number
  default     = 2
}

variable "aws_region" {
  description = "AWS region where the VPC and dependent resources will be deployed."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name used to tag subnets for Kubernetes integration."
  type        = string
  default     = "open-webui-eks"
}
