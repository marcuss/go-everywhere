# go-everywhere
# Multi-Cloud Infrastructure Deployment with Terraform

This project allows you to deploy infrastructure across multiple cloud providers (AWS, Azure, and GCP) using Terraform. You can deploy all providers or selectively deploy specific providers based on a variable input.

## Prerequisites

- Terraform installed on your local machine.
- Valid configurations in the environment-specific variable files (`env/aws.tfvars`, `env/azure.tfvars`, `env/gcp.tfvars`).

## Variables

- `selected_providers`: A list of cloud providers to deploy (e.g., `['aws', 'azure', 'gcp']`).

## Command Usage

### Deploy All Providers (Default)

To deploy infrastructure for AWS, Azure, and GCP:

```sh
terraform apply -var-file=env/aws.tfvars -var-file=env/azure.tfvars -var-file=env/gcp.tfvars -auto-approve
```

### Deploy Only Azure Infrastructure

To deploy only Azure infrastructure:

```sh
terraform apply -var-file=env/azure.tfvars -var="selected_providers=['azure']" -auto-approve
```

### Deploy AWS and Azure Infrastructure

To deploy both AWS and Azure infrastructure:

```sh
terraform apply -var-file=env/aws.tfvars -var-file=env/azure.tfvars -var="selected_providers=['aws', 'azure']" -auto-approve
```

### Deploy Only GCP Infrastructure

To deploy only GCP infrastructure:

```sh
terraform apply -var-file=env/gcp.tfvars -var="selected_providers=['gcp']" -auto-approve
```

## Additional Notes

- Ensure that your environment-specific variable files (e.g., `env/aws.tfvars`, `env/azure.tfvars`, `env/gcp.tfvars`) are correctly configured with the required variables for each provider.
- Use the appropriate `-var-file` arguments to load the necessary configurations for the selected providers.
- Use `-auto-approve` to skip the manual approval step during `terraform apply`.

If you have any questions or encounter issues, please refer to the Terraform documentation or raise an issue in this repository.