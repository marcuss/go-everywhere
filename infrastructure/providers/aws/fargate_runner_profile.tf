# IAM Role for Fargate pod execution
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "fargate_pod_execution_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks-fargate-pods.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })

  tags = {
    business_unit = var.business_unit
    environment   = var.environment
  }
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

# Define Fargate profile for other pods
resource "aws_eks_fargate_profile" "custom_fargate_profile" {
  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = "custom-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = module.vpc.private_subnets

  selector {
    namespace = "default"
    labels = {
      run-on-fargate = "true"
    }
  }

  tags = {
    business_unit = var.business_unit
    environment   = var.environment
  }
}