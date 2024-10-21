# Create an IAM OIDC provider for GitHub
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com" # OIDC provider URL for GitHub

  client_id_list = ["sts.amazonaws.com"] # Audience for the OIDC tokens

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # This is actually not currently used by AWS, specially Github OIDC does validate without a thumbprint
}
