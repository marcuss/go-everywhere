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
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_eks_cluster_name" {
  description = "The name of the AWS EKS cluster"
  type        = string
}

variable "aws_eks_cluster_version" {
  description = "The Kubernetes version for the AWS EKS cluster"
  type        = string
}

variable "local_machine_aws_user" {
  description = "The name of the local machine's AWS user"
  type        = string
}

# Azure Variables
variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "East US 2"
}

variable "azure_aks_cluster_name" {
  description = "The name of the Azure AKS cluster"
  type        = string
}

variable "azure_aks_cluster_version" {
  description = "The Kubernetes version for the Azure AKS cluster"
  type        = string
}

variable "local_machine_azure_user" {
  description = "The name of the local machine's AWS user"
  type        = string
}

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

variable "selected_providers" {
  description = "The cloud providers to deploy. Example: ['aws', 'azure']"
  type        = list(string)
  default     = ["aws", "azure", "gcp"]
}

variable "deploy_aws" {
  description = "Set to true to deploy AWS resources"
  type        = bool
  default     = false
}

variable "deploy_azure" {
  description = "Set to true to deploy Azure resources"
  type        = bool
  default     = false
}
