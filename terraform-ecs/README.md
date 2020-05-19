# terraform-example

Terraform code to provide an example for how to deploy an ECS Fargate Streamlit application authenticated with a local Cognito user pool.

## Prerequisites for guides

- AWS account
- User [AdministratorAccess](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html#jf_administrator)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Terraform >= 0.12.24](https://www.terraform.io/downloads.html)
- [Build/Push Docker image to ECR](../app/README.md#buildingpushing-docker-image-to-aws)

## Setup

1. Update Account ID in the `task-definitions/streamlit-example.json` for the ECR image
1. Update the domain variable in `_main.tf`
1. Initialize Terraform
1. Deploy AWS resources via Terraform
1. Navigate to Cognito console and add user

```
terraform init
terraform apply
```

Type `yes` when prompted by `terraform apply`.
