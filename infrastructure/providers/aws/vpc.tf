provider "aws" {
  region = var.region
  # Optionally include profile, access keys, etc.
}

# Data source to get availability zones dynamically
data "aws_availability_zones" "available" {}

# Local values to limit to the first 3 availability zones and dynamically create subnets
locals {
  selected_azs = slice(data.aws_availability_zones.available.names, 0, 2) # EKS clusters need at least 2 AZs

  public_subnet_cidrs  = [for i in range(length(local.selected_azs)) : cidrsubnet("10.0.0.0/16", 8, i)]
  private_subnet_cidrs = [for i in range(length(local.selected_azs)) : cidrsubnet("10.0.0.0/16", 8, i + 10)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name            = "vpc-${var.business_unit}"
  cidr            = "10.0.0.0/16"
  azs             = local.selected_azs
  public_subnets  = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    business_unit = var.business_unit
    environment = var.environment
  }
}

# Create an IAM OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com" # OIDC provider URL for GitHub

  client_id_list = ["sts.amazonaws.com"] # Audience for the OIDC tokens

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # This is actually not currently used by AWS, specially Github OIDC does validate without a thumbprint
}
