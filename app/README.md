# streamlit-example application

A very basic streamlit example application to show how to build/deploy the application to AWS.

## Building example application

Build the example application as a Docker image:

```
docker build -t streamlit-example -f Dockerfile .
```

Run the application:

```
docker run -p 8501:8501 streamlit-example
```

## Building/pushing Docker image to AWS

Push to your AWS Elastic Container Registry (ECR) repository to be used in the AWS architecture examples.

### Prerequisites

- AWS account
- User with minimum of [AmazonEC2ContainerRegistryPowerUser](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ecr_managed_policies.html#AmazonEC2ContainerRegistryPowerUser) access
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

### Commands

1. Create the ECR repository
1. Authenticate Docker with ECR repository
1. Build Docker image
1. Push to ECR repository

#### Create the ECR repository

We will run the command below:

```
aws ecr create-repository --region us-east-1 --repository-name streamlit-example
```

This will return output like this:

```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:123456789012:repository/streamlit-example",
        "registryId": "123456789012",
        "repositoryName": "streamlit-example2",
        "repositoryUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/streamlit-example",
        "createdAt": 1590716921.0,
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        }
    }
}
```

#### Authenticate Docker with ECR repository

Running the command:

```
eval $(aws ecr get-login --no-include-email --region us-east-1)
```

This will return output like this:

```
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```

#### Build Docker image

We will build our Docker image:

```
docker build -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/streamlit-example:1 .
```

#### Push to ECR repository

Finally we will push our image to ECR:

```
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/streamlit-example:1
```
