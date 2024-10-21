# Define a variable for the local AWS user
variable "local_machine_aws_user" {
  description = "The name of the local machine's AWS user"
  type        = string
}


variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
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

# AWS Variables
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "aws_eks_cluster_name" {
  description = "The name of the AWS EKS cluster"
  type        = string
}

variable "aws_eks_cluster_version" {
  description = "The Kubernetes version for the AWS EKS cluster"
  type        = string
}

# Azure Variables
variable "azure_region" {
  description = "The Azure region to deploy resources in"
  type        = string
}

# Add other Azure-specific variables as needed

# GCP Variables
variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
}

variable "business_unit" {
  description = "Prefix or value to tag resources"
  type        = string
}