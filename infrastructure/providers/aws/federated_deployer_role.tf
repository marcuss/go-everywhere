# Data source to get caller identity
data "aws_caller_identity" "current" {}

# Define a local value for the AWS user ARN
locals {
  local_aws_user_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.local_machine_aws_user}"
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "eks_federated_deployer" {
  name = "eks-federated-deployer" # Role name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.github_oidc.arn # Link directly to OIDC provider ARN
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_user}/${var.github_repo}:*"
          }
        }
      },
      {
        "Sid": "Statement1",
        "Effect": "Allow",
        "Principal": {
          "AWS": local.local_aws_user_arn
        },
        "Action": [
          "sts:AssumeRole"
        ]
      }
    ]
  })

  depends_on = [
    aws_iam_openid_connect_provider.github_oidc
  ]

  tags = {
    business_unit = var.business_unit
    environment = var.environment
  }
}

# Attach permissions policy to the IAM role
resource "aws_iam_role_policy" "eks_federated_deployer_policy" {
  name   = "eks-federated-deployer-policy"                               # Name of the policy
  role   = aws_iam_role.eks_federated_deployer.id                        # The IAM role to attach the policy to
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
  kubernetes_groups = [] # No Kubernetes groups used
  type              = "STANDARD"

  depends_on = [
    module.eks,
    aws_iam_role_policy.eks_federated_deployer_policy
  ]
}

resource "aws_eks_access_policy_association" "federated_deployer_eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_iam_role.eks_federated_deployer.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.eks_federated_deployer_access_entry]
}

# # Associate AmazonEKSAdminViewPolicy  TODO: remove if deployment succeeds without this
# resource "aws_eks_access_policy_association" "cluster_admin_policy" {
#   cluster_name  = module.eks.cluster_name
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.eks_federated_deployer.arn
#
#   access_scope {
#     type = "cluster"
#   }
#
#   depends_on = [aws_eks_access_entry.eks_federated_deployer_access_entry]
# }

# Associate AmazonEKSClusterPolicy
# resource "aws_eks_access_policy_association" "cluster_policy" {
#   cluster_name  = module.eks.cluster_name
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
#   principal_arn = aws_iam_role.eks_federated_deployer.arn
#
#   access_scope {
#     type = "cluster"
#   }
#
#   depends_on = [aws_eks_access_entry.eks_federated_deployer_access_entry]
# }

resource "aws_eks_access_entry" "local_user_access_entry" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = local.local_aws_user_arn
  kubernetes_groups = [] # No Kubernetes groups used
  type              = "STANDARD"

  depends_on = [
    module.eks,
    aws_iam_role_policy.eks_federated_deployer_policy
  ]
}

resource "aws_eks_access_policy_association" "local_aws_user_eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = local.local_aws_user_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.eks_federated_deployer_access_entry]
}