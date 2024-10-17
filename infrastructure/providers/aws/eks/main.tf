provider "aws" {
  region = var.region
  # Assumes 'region' is defined in your variables.tf
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

  name            = "vpc"
  cidr            = "10.0.0.0/16"
  azs             = local.selected_azs
  public_subnets  = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name        = "vpc"
    Environment = var.environment
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.26.0"

  cluster_name                  = var.cluster_name
  cluster_version               = var.cluster_version
  vpc_id                        = module.vpc.vpc_id
  subnet_ids                    = module.vpc.private_subnets
  control_plane_subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  depends_on = [module.vpc]
}

# Define IAM Role for EC2 nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies to the IAM role for EC2 nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Define EC2 nodes group using separate resource block
resource "aws_eks_node_group" "system" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "regular-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
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

  depends_on = [
#     aws_iam_role.eks_node_role,
#     aws_iam_role_policy_attachment.eks_worker_node_policy,
#     aws_iam_role_policy_attachment.eks_cni_policy,
#     aws_iam_role_policy_attachment.ec2_container_registry_read_only,
    module.eks
  ]
}

# Create an IAM OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com" # OIDC provider URL for GitHub

  client_id_list = ["sts.amazonaws.com"] # Audience for the OIDC tokens

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # This is actually not currently used by AWS, specially Github OIDC does validate without a thumbprint
}

# IAM Role for GitHub Actions
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

  depends_on = [aws_iam_openid_connect_provider.github]
}

# Attach permissions policy to the IAM role
resource "aws_iam_role_policy" "eks_federated_deployer_policy" {
  name   = "eks-federated-deployer-policy"        # Name of the policy
  role   = aws_iam_role.eks_federated_deployer.id # The IAM role to attach the policy to
  policy = file("${path.module}/policies/eks-deployer-permissions.json") # Load permissions from a local file

  depends_on = [aws_iam_role.eks_federated_deployer]
}

# Example of adding an access entry to an IAM role without Kubernetes RBAC
#See https://towardsaws.com/enhancing-eks-access-control-ditch-the-aws-auth-configmap-for-access-entry-91683b47e6fc
##see https://github.com/awsdocs/amazon-eks-user-guide/blob/7766e46223c75febc3301645bfdcf06f4146a8a7/doc_source/access-policies.md
# aws eks list-access-policies --output table
resource "aws_eks_access_entry" "eks_federated_deployer_access_entry" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_role.eks_federated_deployer.arn
  kubernetes_groups = []  # No Kubernetes groups used
  type              = "STANDARD"

  depends_on = [aws_iam_role_policy.eks_federated_deployer_policy]
}

# Associate AmazonEKSAdminPolicy
resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_iam_role.eks_federated_deployer.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_iam_role.eks_federated_deployer]
}

# Associate AmazonEKSAdminViewPolicy
resource "aws_eks_access_policy_association" "admin_view_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_federated_deployer.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_iam_role.eks_federated_deployer]
}

# Associate AmazonEKSClusterPolicy
resource "aws_eks_access_policy_association" "cluster_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  principal_arn = aws_iam_role.eks_federated_deployer.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_iam_role.eks_federated_deployer]
}