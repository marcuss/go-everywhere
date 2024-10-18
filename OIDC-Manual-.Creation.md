After a successful cluster creation and verification.

Let's deploy our app with github actions.

Step 1: Set up a Github OIDC


You can read the up-to-date official guide her:
https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

Go to IAM and then Identity Providers

- Select OpenID Connect
- In teh OIDC Identity Provider section click associate identity provider
    Provider URL: https://token.actions.githubusercontent.com
    Audience: sts.amazonaws.com
- Click create

### Create IAM Role

To create an IAM user named `eks-federated-role`, this role will authenticate the actual github repo and nothing more, This distinction ensures that each role has a clear focus and dedicated function, enhancing security and management efficiency.

Create it with the following command:

```sh
aws iam create-role \
  --role-name eks-federated-role \
  --assume-role-policy-document file://federated-role-trust-policy.json
```

Create a second role that will be the actual deployer role, with the following command:

```sh
aws iam create-role \
  --role-name eks-deployer \
  --assume-role-policy-document file://eks-deployer-trust-policy.json
```


### Attach Inline Policy to the User

To attach an inline policy defined in `eks-cluster-admin-permissions-policy.json` to the `eks-federated-deployer` user, use the following command:

```sh
aws iam put-user-policy \
  --user-name eks-deployer \
  --policy-name eks-cluster-admin-permissions-policy \
  --policy-document file://eks-deployer-permissions.json
```


Step 2: Create an ECR repository:

Go to: https://us-east-1.console.aws.amazon.com/ecr/get-started?region=us-east-1

Click create a repository give it a name and leave the default values and click create.

Take not of the URI of the created ecr repo


Step 3: Set Secrets

Go to the settings tab on the repo, and click on Secrets and Variables and click on Actions.

Set the following secrets:

AWS_ACCOUNT_ID: 12 digits number of the aws account being used.
AWS_REGION: us-east-2
ECR_REPOSITORY: take the uri from the previous steo to create the ecr repo.

Step 3: The KUBE_CONFIG_DATA secret