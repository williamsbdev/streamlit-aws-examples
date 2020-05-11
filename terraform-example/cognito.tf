resource "aws_cognito_user_pool" "streamlit_example_user_pool" {
  name                       = "streamlit-example-user-pool"
  auto_verified_attributes   = ["email"]
  mfa_configuration          = "OFF"
  email_verification_subject = "Streamlit Example Access"
  schema {
    name                = "name"
    attribute_data_type = "String"
    mutable             = true
    required            = true
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = false
    required            = true
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_client" "streamlit_example_user_pool_client" {
  name         = "streamlit"
  user_pool_id = aws_cognito_user_pool.streamlit_example_user_pool.id
  supported_identity_providers = [
    "COGNITO"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = [
    "code"
  ]
  allowed_oauth_scopes = [
    "openid",
  ]
  callback_urls = [
    "https://streamlit-example.${var.domain}/oauth2/idpresponse",
    "https://streamlit.auth.${var.region}.amazoncognito.com/saml2/idpresponse",
  ]
  generate_secret = true
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]
}

resource "aws_cognito_user_pool_domain" "streamlit_example_user_pool_domain" {
  domain       = "streamlit-example"
  user_pool_id = aws_cognito_user_pool.streamlit_example_user_pool.id
}

output "aws-cognito-user-pool-id" {
  value = aws_cognito_user_pool.streamlit_example_user_pool.id
}
