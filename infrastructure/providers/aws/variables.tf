variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "github_user" {
  description = "GitHub user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "local_machine_aws_user" {
  description = "Local machine AWS Cli user, to allow to assume the federated deployer role"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider name"
  type        = string
}

variable "business_unit" {
  description = "Prefix or value to tag resources"
  type        = string
}