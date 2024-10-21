#!/bin/bash

# Variables
ROLE_NAME="eks-federated-deployer"
ROLE_SESSION_NAME="eks-federated-deployer-session"
KUBE_CLUSTER_NAME="dev-cluster"
SERVICE_NAME="marco-nico-service"
NAMESPACE="default"

# Get the AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: Unable to retrieve AWS Account ID."
    exit 1
fi

# Assume the role
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
sts_response=$(aws sts assume-role --role-arn $ROLE_ARN --role-session-name $ROLE_SESSION_NAME)

# Parse the assumed role credentials
AWS_ACCESS_KEY_ID=$(echo $sts_response | jq -r '.Credentials.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo $sts_response | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo $sts_response | jq -r '.Credentials.SessionToken')

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
  echo "Error: Unable to assume the role. Please check the role ARN and your AWS CLI configuration."
  exit 1
fi

# Update kubeconfig using the assumed role credentials to switch context
aws eks update-kubeconfig --name $KUBE_CLUSTER_NAME --role-arn $ROLE_ARN

# Use the assumed role credentials with kubectl directly to get the service details
SERVICE_DETAILS=$(AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN kubectl get svc ${SERVICE_NAME} --namespace ${NAMESPACE} -o json)

# Extract the service URL by parsing the JSON response
SERVICE_URL=$(echo $SERVICE_DETAILS | jq -r '.status.loadBalancer.ingress[0].ip // .status.loadBalancer.ingress[0].hostname')

# Check if the SERVICE_URL is not empty
if [ -z "$SERVICE_URL" ]; then
    echo "Error: Unable to retrieve the LoadBalancer URL for the service ${SERVICE_NAME}"
    exit 1
fi

# Print the final service URL
FULL_URL="http://${SERVICE_URL}/play/marco"
echo "The URL is: ${FULL_URL}"