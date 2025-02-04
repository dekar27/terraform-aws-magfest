terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.38.0"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
    curl = {
      source = "marcofranssen/curl"
    }
  }
}

# -------------------------------------------------------------------
# VPC
# -------------------------------------------------------------------

resource "aws_vpc" "uber" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "Ubersystem"
  }
}

# -------------------------------------------------------------------
# Security Groups
# -------------------------------------------------------------------

resource "aws_security_group" "uber_backend" {
  name        = "uber_backend"
  description = "Allow ALB to reach Uber"
  vpc_id      = aws_vpc.uber.id

  ingress {
    description      = "HTTP to Ubersystem Web"
    from_port        = 8282
    to_port          = 8282
    protocol         = "tcp"
    cidr_blocks      = [
      aws_subnet.primary.cidr_block,
      aws_subnet.secondary.cidr_block
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ubersystem Backend"
  }
}

resource "aws_security_group" "uber_rabbitmq" {
  name        = "uber_rabbitmq"
  description = "Allow ALB to reach RabbitMQ"
  vpc_id      = aws_vpc.uber.id

  ingress {
    description      = "RabbitMQ"
    from_port        = 5672
    to_port          = 5672
    protocol         = "tcp"
    cidr_blocks      = [
      aws_subnet.primary.cidr_block,
      aws_subnet.secondary.cidr_block
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ubersystem RabbitMQ"
  }
}

resource "aws_security_group" "uber_redis" {
  name        = "uber_redis"
  description = "Allow Ubersystem to reach Redis"
  vpc_id      = aws_vpc.uber.id

  ingress {
    description      = "Ubersystem Redis"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks      = [
      aws_subnet.primary.cidr_block,
      aws_subnet.secondary.cidr_block
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ubersystem Redis"
  }
}

resource "aws_security_group" "uber_public" {
  name        = "uber_public"
  description = "Allow the Internet to reach Uber"
  vpc_id      = aws_vpc.uber.id

  ingress {
    description      = "Ubersystem HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Ubersystem HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ubersystem Public"
  }
}

resource "aws_security_group" "uber_rds" {
  name        = "uber_rds"
  description = "Allow access to Uber RDS"
  vpc_id      = aws_vpc.uber.id

  ingress {
    description      = "Postgres"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [
        aws_subnet.primary.cidr_block,
        aws_subnet.secondary.cidr_block,
        "0.0.0.0/0"
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ubersystem RDS"
  }
}

resource "aws_security_group" "uber_efs" {
  name        = "uber_efs"
  description = "Allow access to EFS"
  vpc_id      = aws_vpc.uber.id

  ingress {
    description      = "EFS"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = [
        aws_subnet.primary.cidr_block,
        aws_subnet.secondary.cidr_block
    ]
  }

  ingress {
    description      = "EFS Encryption"
    from_port        = 2999
    to_port          = 2999
    protocol         = "tcp"
    cidr_blocks      = [
        aws_subnet.primary.cidr_block,
        aws_subnet.secondary.cidr_block
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Ubersystem EFS"
  }
}

# -------------------------------------------------------------------
# Subnets
# -------------------------------------------------------------------

resource "aws_subnet" "primary" {
  vpc_id                  = aws_vpc.uber.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Ubersystem Primary"
  }
}

resource "aws_subnet" "secondary" {
  vpc_id                  = aws_vpc.uber.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Ubersystem Secondary"
  }
}

resource "aws_db_subnet_group" "uber" {
  name       = "uber"
  subnet_ids = [
    aws_subnet.primary.id,
    aws_subnet.secondary.id
  ]

  tags = {
    Name = "Ubersystem"
  }
}

# -------------------------------------------------------------------
# Routes and Gateways
# -------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.uber.id

  tags = {
    Name = "Ubersystem"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.uber.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }
  
  tags = {
    Name = "Ubersystem"
  }
}

resource "aws_route_table_association" "primary_route" {
  subnet_id      = aws_subnet.primary.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "secondary_route" {
  subnet_id      = aws_subnet.secondary.id
  route_table_id = aws_route_table.public.id
}

# -------------------------------------------------------------------
# ECS Cluster
# -------------------------------------------------------------------

resource "aws_ecs_cluster" "uber" {
  name = "Ubersystem"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_policy" "task_role_logs" {
    name = "UbersystemECSLogs"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogGroup"
                ]
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role" "task_role" {
  name = "UbersystemECSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_logs_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_logs.arn
}

resource "aws_iam_role_policy_attachment" "task_role_default_attach" {
    role = aws_iam_role.task_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------------------------------------------
# Load Balancer
# -------------------------------------------------------------------

resource "aws_acm_certificate" "uber" {
  domain_name       = var.hostname
  validation_method = "DNS"
}

data "aws_route53_zone" "uber" {
  name         = var.zonename
  private_zone = false
}

resource "aws_route53_record" "uber" {
  for_each = {
    for dvo in aws_acm_certificate.uber.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.uber.zone_id
}

resource "aws_acm_certificate_validation" "uber" {
  certificate_arn         = aws_acm_certificate.uber.arn
  validation_record_fqdns = [for record in aws_route53_record.uber : record.fqdn]
}

resource "aws_lb" "ubersystem" {
  name               = "Ubersystem"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    aws_security_group.uber_public.id
  ]
  subnets            = [
    aws_subnet.primary.id,
    aws_subnet.secondary.id
  ]

  enable_deletion_protection = false
}

resource "aws_route53_record" "default" {
  zone_id = data.aws_route53_zone.uber.zone_id
  name    = var.hostname
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.ubersystem.dns_name]
}

resource "aws_lb_listener" "ubersystem_web_http" {
  load_balancer_arn = aws_lb.ubersystem.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "ubersystem_web_https" {
  load_balancer_arn = aws_lb.ubersystem.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.uber.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Unknown ubersystem endpoint"
      status_code  = "404"
    }
  }
}

# -------------------------------------------------------------------
# Elastic File System
# -------------------------------------------------------------------

resource "aws_efs_file_system" "ubersystem_static" {
  creation_token = "ubersystem"

  tags = {
    Name = "Ubersystem"
  }
}

resource "aws_efs_mount_target" "primary" {
  file_system_id  = aws_efs_file_system.ubersystem_static.id
  subnet_id       = aws_subnet.primary.id
  security_groups = [
    aws_security_group.uber_efs.id
  ]
}

resource "aws_efs_mount_target" "secondary" {
  file_system_id  = aws_efs_file_system.ubersystem_static.id
  subnet_id       = aws_subnet.secondary.id
  security_groups = [
    aws_security_group.uber_efs.id
  ]
}

# -------------------------------------------------------------------
# RDS
# -------------------------------------------------------------------

resource "random_password" "uber" {
  length            = 40
  special           = false
  keepers           = {
    pass_version  = 2
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "rds-postgres-passwd"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.uber.result
}

resource "aws_db_instance" "uber" {
  allocated_storage      = 10
  db_name                = "uber"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
#  identifier             = "ubersystem"
  username               = "postgres"
  password               = aws_secretsmanager_secret_version.password.secret_string
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = true
  vpc_security_group_ids = [
    aws_security_group.uber_rds.id
  ]
  db_subnet_group_name   = aws_db_subnet_group.uber.name
  depends_on = [
    aws_route_table_association.primary_route,
    aws_route_table_association.secondary_route
  ]
}

provider "postgresql" {
  host       = aws_db_instance.uber.address
  username   = aws_db_instance.uber.username
  password   = aws_secretsmanager_secret_version.password.secret_string
  superuser  = false
}

data "curl_request" "ghcr_token" {
  http_method = "GET"
  uri = "https://ghcr.io/token?scope=repository:magfest/magprime:pull"
  lifecycle {
    postcondition {
      condition = self.response_status_code == 200
      error_message = "Invalid response code getting login token: ${self.response_status_code}\n\n${self.response_body}"
    }
  }
}

provider "curl" {
  alias = "ghcr"
  token = jsondecode(data.curl_request.ghcr_token.response_body).token
}