# Outputs for convenience
output "region" {
  description = "The AWS region where resources were deployed"
  value       = var.region
}

output "github_user" {
  description = "The GitHub user name"
  value       = var.github_user
}

output "github_repo" {
  description = "The GitHub repository name"
  value       = var.github_repo
}

output "cloud_provider" {
  description = "The cloud provider being used"
  value       = var.cloud_provider
}

output "eks_federated_deployer_role_name" {
  description = "The name of the IAM role for EKS federated deployer"
  value       = aws_iam_role.eks_federated_deployer.name # Output the role name
}

output "eks_node_role_role_name" {
  description = "The name of the IAM role for EKS node role"
  value       = aws_iam_role.eks_node_role.name # Output the role name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}