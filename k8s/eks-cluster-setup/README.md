# EKS Cluster Setup Guide

This guide will help you set up an Amazon EKS cluster using AWS Management Console and AWS CLI.
## Official Guide:
You can follow the official up-to-date guide here:
[Get started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html)
Or a more straight forward version, continue reading.

## Step 1: Create Cluster Admin User
- With an admin access user go to IAM and create a user named: `eks-cluster-admin`
- Create a password and give it access to the AWS console login. if asked click on only create IAM user.
- Select attach inline policy in this file: [here](./eks-cluster-admin-permissions-policy.json)

  Which adds plenty of permissions to the `eks-cluster-admin` user to perform almost every action possible.
    Best practices suggest fewer permissions and this is not a policy you should use in production.

- Create access keys for the cluster admin user, for case select Command Line Interface (CLI), take note of the created access keys.
- Sign off and re-login with your newly created user.

## Step 2: Configure your AWSCLI
Configure your AWSCLI with proper AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, from the previous step, make sure the user you choose to do this is the one you are now Signed in to the AWS console, if this is not done this
way and a root user is used for the aws console steps it will cause many problems.

In a terminal window, run the following:
```sh
aws configure
```
double check everything went fine:

```sh
aws sts get-caller-identity
```
After this command is run, the user in the answer must be the same as the user you are logged in to the AWS console. it should look something like the following:

```sh
{
"UserId": "***************3I",
"Account": "*********13",
"Arn": "arn:aws:iam::***********13:user/eks-cluster-admin"
}
```

## Step 3: Create VPC
Now with users set, lets start building, execute the following:
```sh
aws cloudformation create-stack \
  --region us-east-1 \
  --stack-name eks-vpc-stack \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
```

## Step 2: Create IAM Role for EKS Cluster

- Create the role:

    ```sh
    aws iam create-role \
      --role-name eks-service-role \
      --assume-role-policy-document file://"eks-service-role-trust-policy.json"
    ```
    This creates the role and attach the trust policy in the mentioned file to it, which basically creates a role and allows the actual EKS service to assume it.


- Attach the EKS Cluster Policy:

    ```sh
    aws iam attach-role-policy \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
      --role-name eks-service-role
    ```

## Step 3: Create EKS Cluster

1. Open the Amazon EKS console: [EKS Console](https://console.aws.amazon.com/eks/home#/clusters).
2. Ensure the correct AWS Region is selected.
3. Choose **Add cluster** > **Create**.
4. Configure Cluster:
    - **Name:** `eks-cluster`
    - **Cluster Service Role:** `eks-service-role`
5. Specify Networking:
    - **VPC:** Select the VPC created in Step 1.
6. Configure Observability: Leave defaults.
7. Add-ons: Leave defaults.
7. Review and create the cluster: Create

## Step 4: Configure kubectl locally to connect to the AWS cluster

1. Update kubeconfig:

    ```sh
    aws eks update-kubeconfig --region us-east-1 --name eks-cluster
    ```

2. Verify configuration:

    ```sh
    kubectl get svc
    ```
    Which should look something like:
    ```sh
    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   6m39s
   ```
    With no permissions errors.

    or try:
    ```sh
    kubectl cluster-info
    ```

## Step 5: Create IAM role for the Fargate Profile

- Create the role:

    ```sh
    aws iam create-role \
      --role-name eks-fargate-runner-role \
      --assume-role-policy-document file://"eks-fargate-profile-runner-trust-policy"
    ```
  This creates the role and attach the trust policy in the mentioned file to it, which basically creates a role and allows the Fargate Profile to assume it.



-   Attach the Fargate Policy:

    ```sh
    aws iam attach-role-policy \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy \
      --role-name AmazonEKSFargatePodExecutionRole
    ```

- Create Fargate Profile in EKS Console:

    Open  https://console.aws.amazon.com/eks/home#/clusters click on the cluster name you just created, and go to the **Compute** tab, click on create new fargate profile and use the following values:
  - **Profile Name:** `fargate-runner-profile`
  - **Pod Execution Role:** `eks-fargate-runner-role`
  - **Subnets:** Select only the 2 private subnets created on step 3.
  - **Namespace:** `default`

## Step 6: Verify Everything went smooth.

With everything set up, lets try to deploy a test pod:

```sh
kubectl apply -f fargate-test-pod-deployment.yaml
```
it should respond:
deployment.apps/nginx-deployment created

```sh
kubectl get pods
```

it should respond something like:
```sh
NAME                                READY   STATUS    RESTARTS   AGE
nginx-54b9c68f67-6zwqg   1/1     Running   0          16m
```

If you don't get that Running status, you may want to start from scratch (recommended), or try troubleshooting with a list of the events that has happened to the pod with the following command:


```sh
 kubectl get events | grep nginx-<full-pod-name-as-in-get-pod-response>
```

## Step 7: Delete Test Deployment.

```sh
kubectl delete -f fargate-test-pod-deployment.yaml  
```