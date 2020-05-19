resource "aws_security_group" "streamlit_example_alb_security_group" {
  name        = "streamlit-example-alb-security-group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.streamlit.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    from_port = 8501
    to_port   = 8501
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.streamlit.cidr_block
    ]
  }
  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_lb" "streamlit_example_alb" {
  name               = "streamlit-example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.streamlit_example_alb_security_group.id
  ]
  subnets = [
    aws_subnet.public_az_1.id,
    aws_subnet.public_az_2.id,
    aws_subnet.public_az_3.id,
  ]
}

# This assumes that a hosted zone already exists for the domain
resource "aws_route53_record" "alb_a_record" {
  name    = "streamlit-example.${var.domain}"
  type    = "A"
  zone_id = data.aws_route53_zone.domain.id
  alias {
    name                   = aws_lb.streamlit_example_alb.dns_name
    zone_id                = aws_lb.streamlit_example_alb.zone_id
    evaluate_target_health = false
  }
}

# This assumes that certificate already exists for the domain and
# streamlit.<domain>
# or
# *.<domain>
data "aws_acm_certificate" "alb_certificate" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "streamlit_example_alb_listener" {
  load_balancer_arn = aws_lb.streamlit_example_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = data.aws_acm_certificate.alb_certificate.arn

  default_action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn              = aws_cognito_user_pool.streamlit_example_user_pool.arn
      user_pool_client_id        = aws_cognito_user_pool_client.streamlit_example_user_pool_client.id
      user_pool_domain           = aws_cognito_user_pool_domain.streamlit_example_user_pool_domain.domain
      session_cookie_name        = "AWSELBAuthSessionCookie"
      session_timeout            = 120
      scope                      = "openid"
      on_unauthenticated_request = "authenticate"
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.streamlit_example_target_group.arn
  }
}

resource "aws_lb_target_group" "streamlit_example_target_group" {
  name                 = "streamlit-example"
  port                 = 8501
  protocol             = "HTTP"
  vpc_id               = aws_vpc.streamlit.id
  target_type          = "ip"
  deregistration_delay = 10
  health_check {
    enabled             = true
    interval            = 5
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
  depends_on = [
    aws_lb.streamlit_example_alb
  ]
}

output "streamlit-alb-dns-name" {
  value = aws_lb.streamlit_example_alb.dns_name
}
