provider "aws" {
  region = var.region  # Use the region specified in the variables
}

# Data source to get availability zones dynamically
data "aws_availability_zones" "available" {}

# Local values to limit to the first 3 availability zones and dynamically create subnets
locals {
  selected_azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnet_cidrs = [for i in range(length(local.selected_azs)) : cidrsubnet("10.0.0.0/16", 8, i)]
  private_subnet_cidrs = [for i in range(length(local.selected_azs)) : cidrsubnet("10.0.0.0/16", 8, i + 10)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"  # Use a compatible version

  name = "vpc"
  cidr = "10.0.0.0/16"

  azs             = local.selected_azs
  public_subnets  = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name        = "vpc"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.26.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.31"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  # Define Fargate profile
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
    }
  }
}

# Create an IAM OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com" # OIDC provider URL for GitHub

  client_id_list = ["sts.amazonaws.com"] # Audience for the OIDC tokens

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # This is actually not currently used by AWS, specially Github OIDC does validate without a thumbprint
}

# Create the IAM role with trust policy
resource "aws_iam_role" "eks_federated_deployer" {
  name               = "eks-federated-deployer"  # Role name
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": aws_iam_openid_connect_provider.github.arn  # Link directly to OIDC provider ARN
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:${var.github_user}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# Attach permissions policy to the IAM role
resource "aws_iam_role_policy" "eks_federated_deployer_policy" {
  name   = "eks-federated-deployer-policy"        # Name of the policy
  role   = aws_iam_role.eks_federated_deployer.id # The IAM role to attach the policy to
  policy = file("providers/aws/policies/eks-deployer-permissions.json")  # Load permissions from a local file
}

# Create the EKS cluster auth mapping for the IAM role
resource "aws_eks_cluster_auth" "eks_federated_deployer_auth" {
  cluster_name = module.eks.cluster_id
  role_arn     = aws_iam_role.eks_federated_deployer.arn
}

# Outputs for convenience
output "eks_federated_deployer_role_name" {
  description = "The name of the IAM role for EKS federated deployer"
  value       = aws_iam_role.eks_federated_deployer.name # Output the role name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}