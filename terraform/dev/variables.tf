################################################################################
# Input Variables — Dev Environment
# ------------------------------------------------------------------------------
# These parameters define the deployment region and EKS cluster name for
# the development environment. Override these via terraform.tfvars or CLI
# when deploying in staging or production.
################################################################################

variable "aws_region" {
  description = "AWS region where the development environment is deployed."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster for this environment."
  type        = string
  default     = "open-webui-eks"
}
