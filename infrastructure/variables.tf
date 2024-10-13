variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2" # You can set your preferred default region here
}

variable "github_user" {
  description = "GitHub user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "cloud_provider" {
  description = "Cloud Provider"
  type        = string
}