################################################################################
# Terraform Provider Configuration
# ------------------------------------------------------------------------------
# Defines the AWS provider and required Terraform version constraints.
# Ensures consistent runtime behavior across all environments.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Enforces minimum Terraform version for compatibility with current module versions
  required_version = ">= 1.6.0"
}

# ------------------------------------------------------------------------------
# AWS Provider
# ------------------------------------------------------------------------------
# The provider inherits region from variables (aws_region) defined in this
# environment’s variable files or tfvars. AWS credentials are expected to be
# configured via CLI profile, environment variables, or SSO.
# ------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}
