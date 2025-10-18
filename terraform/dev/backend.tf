################################################################################
# Terraform Backend Configuration
# ------------------------------------------------------------------------------
# The backend defines where Terraform state is stored. 
# For this assessment, we’re using a local backend for simplicity.
#
# In production, this would typically be replaced with an S3
# remote backend for state locking and versioning.
################################################################################

terraform {
  backend "local" {
    # Path to the local Terraform state file
    # (Stored under the current working directory)
    path = "terraform.tfstate"
  }
}
