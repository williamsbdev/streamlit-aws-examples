resource "aws_ecs_cluster" "streamlit_fargate_example" {
  name = "streamlit-fargate-example"
}

resource "aws_iam_role" "streamlit_ecs_execution_role" {
  name = "streamlit-ecs-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "streamlit_ecs_execution_policy_attachment" {
  role       = aws_iam_role.streamlit_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "streamlit_example_application_security_group" {
  name        = "streamlit-example-application-security-group"
  description = "Allow traffic from ALB to streamlit application"
  vpc_id      = aws_vpc.streamlit.id
  ingress {
    from_port = 8501
    to_port   = 8501
    protocol  = "tcp"
    security_groups = [
      aws_security_group.streamlit_example_alb_security_group.id
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_ecs_task_definition" "streamlit_example_task_definition" {
  family                   = "streamlit-example"
  container_definitions    = file("task-definitions/streamlit-example.json")
  execution_role_arn       = aws_iam_role.streamlit_ecs_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "streamlit_example_service" {
  name            = "streamlit_example_service"
  cluster         = aws_ecs_cluster.streamlit_fargate_example.id
  task_definition = aws_ecs_task_definition.streamlit_example_task_definition.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.streamlit_example_target_group.arn
    container_name   = "streamlit-example"
    container_port   = 8501
  }
  network_configuration {
    assign_public_ip = true
    security_groups = [
      aws_security_group.streamlit_example_application_security_group.id
    ]
    subnets = [
      aws_subnet.public_az_1.id,
      aws_subnet.public_az_2.id,
      aws_subnet.public_az_3.id,
    ]
  }
}
