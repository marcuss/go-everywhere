# Outputs for convenience
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