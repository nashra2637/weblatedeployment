locals {
  # Ids for multiple sets of EC2 instances, merged together
  deployment          = ["blue", "green"]
  listener_ports      = [80, 8080]
}

/*====
Cloudwatch Log Group
======*/
resource "aws_cloudwatch_log_group" "weblate" {
  name = "${var.name}-${var.environment}-weblate"

  tags = {
    Environment = "${var.environment}"
    Application = "Weblate"
  }
}


/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "weblate" {
  name = "${var.name}-${var.environment}-ecs-weblate"
}

/*====
ECS task definitions
======*/

resource "aws_ecs_task_definition" "weblate" {
  family                   = "${var.name}-${var.environment}-taskdef"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = "${aws_iam_role.execution_role.arn}"

  volume {
      name      = "weblate-volume"
    }
  volume {
      name      = "redis-volume"
    }


  # defined in role.tf
  task_role_arn = "${aws_iam_role.execution_role.arn}"

  container_definitions = <<DEFINITION
[
  {
    "name": "weblate",
    "image": "weblate/weblate",
    "essential": false,
    "readonlyRootFilesystem": false,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "environment": [
      {
        "name": "POSTGRES_DATABASE",
        "value": "${var.database_name}"
      },
      {
        "name": "POSTGRES_HOST",
        "value": "${var.database_endpoint}"
      },
      {
        "name": "POSTGRES_PASSWORD",
        "value": "${var.database_password}"
      },
      {
        "name": "POSTGRES_USER",
        "value": "${var.database_username}"
      },
      {
        "name": "POSTGRES_PORT",
        "value": "5432"
      },
      {
        "name": "REDIS_HOST",
        "value": "localhost"
      },
      {
        "name": "REDIS_PORT",
        "value": "6379"
      },
      {
        "name": "WEBLATE_ADMIN_EMAIL",
        "value": "${var.email_address}"
      },
      {
        "name": "WEBLATE_ADMIN_NAME",
        "value": "Weblate Admin"
      },
      {
        "name": "WEBLATE_ADMIN_PASSWORD",
        "value": "test123"
      },
      {
        "name": "WEBLATE_ALLOWED_HOSTS",
        "value": "localhost,${aws_lb.weblate.dns_name}"
      },
      {
        "name": "WEBLATE_DEFAULT_FROM_EMAIL",
        "value": "${var.email_address}"
      },
      {
        "name": "WEBLATE_EMAIL_HOST",
        "value": "smtp.gmail.com"
      },
      {
        "name": "WEBLATE_EMAIL_HOST_PASSWORD",
        "value": "task@1235"
      },
      {
        "name": "WEBLATE_EMAIL_HOST_USER",
        "value": "nashra"
      },
      {
        "name": "WEBLATE_SERVER_EMAIL",
        "value": "${var.email_address}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.name}-${var.environment}-weblate",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "mountPoints": [
      {
        "readOnly": null,
        "containerPath": "/app/data",
        "sourceVolume": "weblate-volume"
      }
    ]
  },
  {
    "name": "redis",
    "image": "redis:5-alpine",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 6379,
        "hostPort": 6379
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.name}-${var.environment}-weblate",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "mountPoints": [
      {
        "readOnly": null,
        "containerPath": "/data",
        "sourceVolume": "redis-volume"
      }
    ],
    "command": [
        "redis-server",
        "--appendonly",
        "yes"
    ]
  }
]
DEFINITION


  tags = {
    Environment = "${var.environment}"
    Name = "${var.name}-${var.environment}-task-definition"
  }
}

/*====
App Load Balancer
======*/

/* security group for ALB */
resource "aws_security_group" "weblate_sg" {
  name        = "${var.name}-${var.environment}-weblate-sg"
  vpc_id      = "${var.vpc_id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-weblate-sg"
  }
}

resource "aws_security_group_rule" "weblate_sg_rule" {
  count                    = "${length(local.listener_ports)}"
  type                     = "ingress"
  from_port                = "${element(local.listener_ports, count.index)}"
  to_port                  = "${element(local.listener_ports, count.index)}"
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = "${aws_security_group.weblate_sg.id}"
}

resource "aws_lb" "weblate" {
  name               = "${var.name}-${var.environment}-nlb-weblate"
  internal           = false
  load_balancer_type = "network"
  subnets            = "${compact(split(",", var.public_subnet_ids))}"

  enable_deletion_protection = false

  tags = {
    Name        = "${var.name}-${var.environment}nalb-weblate"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group" "weblate_tg" {
  count       = "${length(local.deployment)}"
  name        = "${var.name}-${var.environment}-tg-weblate-${local.deployment[count.index]}"
  port        = 8080
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_lb_listener" "weblate_listener" {
  count             = "${length(local.listener_ports)}"
  load_balancer_arn = "${aws_lb.weblate.arn}"
  port              = "${element(local.listener_ports, count.index)}"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = "${element(aws_lb_target_group.weblate_tg.*.arn, count.index)}"
  }
}

# /*====
# ECS service
# ======*/

# /* Security Group for ECS */
resource "aws_security_group" "ecs_service" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.name}-${var.environment}-ecs-service-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = {
    Name        = "${var.environment}-ecs-service-sg"
    Environment = "${var.environment}"
  }
}

# # /* Simply specify the family to find the latest ACTIVE revision in that family */
resource "aws_ecs_service" "weblate" {
  name            = "${var.name}-${var.environment}-weblate"
  task_definition = "${aws_ecs_task_definition.weblate.family}:${max("${aws_ecs_task_definition.weblate.revision}")}"
  desired_count   = 2
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.weblate.id}"
  depends_on      = ["aws_lb_target_group.weblate_tg"]

  network_configuration {
    security_groups = ["${aws_security_group.ecs_service.id}"]
    subnets = "${compact(split(",", var.public_subnet_ids))}"
    assign_public_ip = true
  //  subnets         = "${var.subnet_ids}"
  }
  
  deployment_controller {
    type            = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = "${element(aws_lb_target_group.weblate_tg.*.arn, 0)}"
    container_name   = "weblate"
    container_port   = "8080"
  }
}

