provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type    = string
  default = "streamlit.io"
}

# This assumes that a hosted zone already exists for the domain
data "aws_route53_zone" "domain" {
  name         = "${var.domain}."
  private_zone = false
}
