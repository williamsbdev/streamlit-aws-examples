# streamlit-aws-examples

Repo containing AWS examples for building/deploying a Streamlit application.

## Prerequisites for guides

- AWS account
- User [AdministratorAccess](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html#jf_administrator)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## Running locally

Streamlit is as easy `pip install streamlit` (either globally or in a virtualenv) and then running `streamlit hello`.

## Building example application

Build the example application as a Docker image:

```
docker build -t streamlit-example -f app/Dockerfile app
```

Run the application:

```
docker run -p 8501:8501 streamlit-example
```
