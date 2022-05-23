
resource "aws_ecs_task_definition" "aws-ecs-task-blue" {
  family = "${var.app_name}-task-blue"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container-blue",
      "image": "nginx:latest",
      "entryPoint": [],
      
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_environment}"
        }
      },
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }
}

data "aws_ecs_task_definition" "main-blue" {
  task_definition = aws_ecs_task_definition.aws-ecs-task-blue.family
}

resource "aws_ecs_service" "aws-ecs-service-blue" {
  name                 = "${var.app_name}-${var.app_environment}-ecs-service-blue"
  cluster              =  aws_ecs_cluster.aws-ecs-cluster-zemoga-app.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task-blue.family}:${max(aws_ecs_task_definition.aws-ecs-task-blue.revision, data.aws_ecs_task_definition.main-blue.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.app_environment}-container-blue"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }


  depends_on = [aws_lb_listener.listener]
}

