# aws-cli-example

AWS CLI guide to provide an example for how to deploy an ECS Fargate Streamlit application authenticated with a local Cognito user pool.

## Prerequisites for guides

- AWS account
- User [AdministratorAccess](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html#jf_administrator)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Build/Push Docker image to ECR](../example-app/README.md#buildingpushing-docker-image-to-aws)
- AWS default region of [`us-east-1`](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration)

## Setup

Before starting, be sure that you've followed the [instructions](../example-app/README.md#buildingpushing-docker-image-to-aws) for building the example Docker image and pushing to ECR.

There are many ways to configure authentication, especially with Identity Providers (IDPs) through AWS Cognito but for now we will configure a local AWS Cognito user pool to use for securing access to the Streamlit application.

```
aws cognito-idp create-user-pool --pool-name streamlit-example-user-pool
```

If you did not get the `Id` from the above command, it can be found by running the command below and locating the `streamlit-example-user-pool` and copying the `Id` value for creating the application client.

```
aws cognito-idp list-user-pools --max-results 10
```

The above command provides the `Id` we will need for the next command to create the App client to be used by the Application Load Balancer (ALB).

```
aws cognito-idp create-user-pool-client \
  --user-pool-id us-east-1_aaaaaaaaa \
  --client-name streamlit \
  --generate-secret \
  --allowed-o-auth-flows-user-pool-client \
  --allowed-o-auth-flows "code" \
  --allowed-o-auth-scopes "openid" \
  --explicit-auth-flows "ALLOW_REFRESH_TOKEN_AUTH" "ALLOW_USER_PASSWORD_AUTH" \
  --supported-identity-providers "COGNITO" \
  --callback-urls "https://example.streamlit.io/oauth2/idpresponse" "https://streamlit.auth.us-east-1.amazoncognito.com/saml2/idpresponse"
```

Be sure to save off the value of the `ClientId` key for later when creating the listener on the ALB.

Next we'll create a domain for use by the App client.

```
aws cognito-idp create-user-pool-domain \
  --user-pool-id us-east-1_aaaaaaaaa \
  --domain streamlit
```

Finally, let's create our first user:

```
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_aaaaaaaaa \
  --username newuser@streamlit.io \
  --user-attributes Name=email,Value=newuser@streamlit.io \
  --desired-delivery-mediums "EMAIL"
```

Now that we've configured our Cognito local user pool, App client, and domain, we can configure the ALB. This guide will assume that we can use the default Virtual Private Cloud (VPC) created with your AWS account. First we'll need to get two default public subnets:

```
aws ec2 describe-subnets \
  --filters "Name=availability-zone,Values=us-east-1a,us-east-1b" \
  --query 'Subnets[*].SubnetId'
```

Use the two subnets in the next command to create the load balancer:

```
aws elbv2 create-load-balancer \
  --name streamlit-example-alb \
  --subnets subnet-9999aabb subnet-8888ccdd
```

Before creating the Target Group, we will first need to get the default VPC created with the account:

```
aws ec2 describe-vpcs --query 'Vpcs[*].VpcId'
```

Create the Target Group that will be used in the listener on the ALB and to which the Elastic Container Service Fargate applications will be connected.

```
aws elbv2 create-target-group \
  --name streamlit-example \
  --protocol HTTP \
  --port 8501 \
  --vpc-id vpc-7777aabb \
  --target-type ip
```

In order to use Cognito authentication with your ALB, it is required that you use TLS on the ALB listener. In order to configure TLS, we will need a SSL certificate which can be requested/managed through the Amazon Certificate Manager service (replacing `streamlit.io` with your domain).

```
aws acm request-certificate \
  --domain-name streamlit.io \
  --subject-alternative-names "*.streamlit.io" \
  --validation-method DNS
```

This will create a DNS record that will need to be added to your domain. Use the Amazon Resource Name (ARN) from the command above to query and get the DNS CNAME record you need to add.

```
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb \
  --query 'Certificate.DomainValidationOptions[0]'
```

This will provide the `ResourceRecord` that needs added.

Next we will create Listener on the ALB. For this we will need:

- certificate ARN (used above)
- ALB ARN
- Target Group ARN
- Cognito User Pool ARN (e.g. `arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_aaaaaaaaa` where you use the `Id` to replace the `us-east-1_aaaaaaaa` from above)
- Cognito User Pool Client ID
- Cognito User Pool Domain

ALB ARN
```
aws elbv2 describe-load-balancers \
  --names streamlit-example-alb \
  --query 'LoadBalancers[0].LoadBalancerArn'
```

Target Group ARN
```
aws elbv2 describe-target-groups \
  --names streamlit-example \
  --query 'TargetGroups[0].TargetGroupArn'
```

We'll create an `actions.json` file to be used when creating the listener:

```actions.json
[
  {
    "Type": "authenticate-cognito",
    "AuthenticateCognitoConfig": {
      "UserPoolArn": "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_aaaaaaaaa",
      "UserPoolClientId": "abcdefghijklmnopqrstuvwxyz123456789",
      "UserPoolDomain": "streamlit",
      "SessionCookieName": "AWSELBAuthSessionCookie",
      "SessionTimeout": 3600,
      "Scope": "openid",
      "OnUnauthenticatedRequest": "authenticate"
    },
    "Order": 1
  },
  {
    "Type": "forward",
    "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/streamlit-example/abcdefg123456789",
    "Order": 2
  }
]
```

Use the values retrieved above to fill in the values `<resource-arn>` below:

```
aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTPS
  --port 443
  --ssl-policy ELBSecurityPolicy-TLS-1-2-Ext-2018-06
  --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/abc12345-4419-4311-910a-2438cd4d3d99 \
  --default-actions file://actions.json
```

Now that we've configured the ALB with authentication, we now need to create the Elastic Container Service (ECS) cluster/service/task definition.

Create Fargate ECS cluster:
```
aws ecs create-cluster --cluster-name streamlit-fargate-example
```

Create the ECS task definition execution role:

```
aws iam create-role \
  --role-name streamlit-ecs-execution-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
```

Attach the `AmazonECSTaskExecutionRolePolicy` AWS managed policy to the role:

```
aws iam attach-role-policy \
  --role-name streamlit-ecs-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

Create ECS task definition:

```
aws ecs register-task-definition \
  --family streamlit-example \
  --network-mode awsvpc \
  --requires-compatibilities "FARGATE" \
  --cpu 256 \
  --memory 512 \
  --execution-role-arn arn:aws:iam::123456789012:role/streamlit-ecs-execution-role \
  --container-definitions '[{"name": "streamlit-example", "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/streamlit-example:1", "essential": true, "portMappings": [{"containerPort": 8501}]}]'
```

We need the default security group to use when creating the ECS service.

```
aws ec2 describe-security-groups \
  --filters 'Name=group-name,Values=default' \
  --query 'SecurityGroups[*].GroupId'
```

Create ECS service:
```
aws ecs create-service \
  --cluster streamlit-fargate-example \
  --service-name streamlit-example \
  --launch-type "FARGATE" \
  --desired-count 1 \
  --task-definition streamlit-example \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/streamlit-example/abcde01234567890,containerName=streamlit-example,containerPort=8501 \
  --network-configuration awsvpcConfiguration={subnets=[subnet-abc9ecdd,subnet-1234573b],securityGroups=[sg-abc372d7],assignPublicIp=ENABLED}
```

Finally, update the default security group to allow ingress traffic:

```
aws ec2 authorize-security-group-ingress \
  --group-name default \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```
