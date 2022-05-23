resource "aws_vpc" "aws-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = var.app_environment
  }
}

resource "aws_internet_gateway" "aws-igw" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = {
    Name        = "${var.app_name}-igw"
    Environment = var.app_environment
  }

}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.aws-vpc.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.app_name}-private-subnet-${count.index + 1}"
    Environment = var.app_environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-public-subnet-${count.index + 1}"
    Environment = var.app_environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.aws-vpc.id

  tags = {
    Name        = "${var.app_name}-routing-table-public"
    Environment = var.app_environment
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.aws-igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.aws-vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "${var.app_name}-${var.app_environment}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.load_balancer_security_group.id]

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.app_environment
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = aws_vpc.aws-vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

      ingress {
    from_port        = 8088
    to_port          = 8088
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = "${var.app_name}-sg"
    Environment = var.app_environment
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.app_name}-${var.app_environment}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.aws-vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.app_name}-lb-tg"
    Environment = var.app_environment
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}

resource "aws_lb_listener" "listener2" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "fixed response"
      status_code = "503"
    }
    
  }
}

resource "aws_lb_listener" "listener3" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "8088"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
        fixed_response {
      content_type = "text/plain"
      message_body = "fixed response"
      status_code = "503"
    }
    
  }
}