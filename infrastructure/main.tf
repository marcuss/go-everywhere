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

  name           = "vpc"
  cidr           = "10.0.0.0/16"
  azs            = local.selected_azs
  public_subnets = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name        = "vpc"
    Environment = "dev"
  }
}

# IAM Role for Fargate pod execution
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "fargate_pod_execution_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks-fargate.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Attach the needed policies to the Fargate pod execution role
resource "aws_iam_role_policy_attachment" "fargate_ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.fargate_pod_execution_role.name
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

  # Define Fargate profile for other pods
  fargate_profiles = {
    # Define Fargate profile for pods marked with the 'run-on-fargate=true' label
    custom_fargate_profile = {
      name                = "custom-fargate-profile"
      pod_execution_role  = aws_iam_role.fargate_pod_execution_role.name
      selectors = [
        {
          namespace = "default"
          labels = {
            run-on-fargate = "true"
          }
        }
      ]
    }
  }
}

# Define IAM Role for EC2 nodes
resource "aws_iam_role" "eks-federated-deployer" {
  name = "eks-federated-deployer"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": aws_iam_openid_connect_provider.github.arn
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

# Attach policies to the IAM role for EC2 nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-federated-deployer.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-federated-deployer.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-federated-deployer.name
}

# Attach additional policies for the GitHub Actions
resource "aws_iam_role_policy" "eks_node_deployer_policy" {
  name   = "eks-node-deployer-policy"
  role   = aws_iam_role.eks-federated-deployer.id
  policy = file("providers/aws/policies/eks-deployer-permissions.json")
}

# Define EC2 nodes group using separate resource block
resource "aws_eks_node_group" "system" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "regular-nodes"
  node_role_arn   = aws_iam_role.eks-federated-deployer.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]

  tags = {
    Name        = "regular-nodes"
    Environment = "dev"
  }
}

# Create an IAM OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com" # OIDC provider URL for GitHub

  client_id_list = ["sts.amazonaws.com"] # Audience for the OIDC tokens

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # This is actually not currently used by AWS, specially Github OIDC does validate without a thumbprint
}

# Outputs for convenience
output "eks_federated_deployer_role_name" {
  description = "The name of the IAM role for EKS federated deployer"
  value       = aws_iam_role.eks-federated-deployer.name # Output the role name
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