resource "aws_ecr_repository" "app" {
  name                 = var.project
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project}-api"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.project}-worker"
  retention_in_days = 30
}

# --- IAM ---

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Pulls the image and writes logs; not the app's own AWS permissions.
resource "aws_iam_role" "execution" {
  name               = "${var.project}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = var.task_env_secrets_arn == null ? 0 : 1
  name  = "${var.project}-execution-read-secret"
  role  = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.task_env_secrets_arn]
    }]
  })
}

# The app's own AWS permissions at runtime. Empty for v1 (Supabase/Plaid/
# Stripe/DeepSeek are all reached over HTTPS, not AWS APIs) — attach
# policies here if that changes.
resource "aws_iam_role" "task" {
  name               = "${var.project}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# --- Task definitions ---
# container_image is unset until the first image is pushed to ECR
# (CHECKLIST.md step 4); terraform apply fails fast rather than
# silently deploying `null`.

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project}-api"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = var.api_cpu
  memory                    = var.api_memory
  execution_role_arn        = aws_iam_role.execution.arn
  task_role_arn             = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = "api"
    image     = var.container_image
    essential = true
    command   = ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", tostring(var.api_container_port)]
    portMappings = [{
      containerPort = var.api_container_port
      protocol      = "tcp"
    }]
    secrets = var.task_env_secrets_arn == null ? [] : [
      { name = "SUPABASE_URL", valueFrom = "${var.task_env_secrets_arn}:SUPABASE_URL::" },
      { name = "SUPABASE_SERVICE_KEY", valueFrom = "${var.task_env_secrets_arn}:SUPABASE_SERVICE_KEY::" },
      { name = "DEEPSEEK_API_KEY", valueFrom = "${var.task_env_secrets_arn}:DEEPSEEK_API_KEY::" },
      { name = "STRIPE_SECRET_KEY", valueFrom = "${var.task_env_secrets_arn}:STRIPE_SECRET_KEY::" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "api"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project}-sync-worker"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = var.worker_cpu
  memory                    = var.worker_memory
  execution_role_arn        = aws_iam_role.execution.arn
  task_role_arn             = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = "sync-worker"
    image     = var.container_image
    essential = true
    command   = ["python", "-m", "src.worker.main"]
    secrets = var.task_env_secrets_arn == null ? [] : [
      { name = "SUPABASE_URL", valueFrom = "${var.task_env_secrets_arn}:SUPABASE_URL::" },
      { name = "SUPABASE_SERVICE_KEY", valueFrom = "${var.task_env_secrets_arn}:SUPABASE_SERVICE_KEY::" },
      { name = "PLAID_CLIENT_ID", valueFrom = "${var.task_env_secrets_arn}:PLAID_CLIENT_ID::" },
      { name = "PLAID_SECRET", valueFrom = "${var.task_env_secrets_arn}:PLAID_SECRET::" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.worker.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "worker"
      }
    }
  }])
}

# --- Load balancer (API service only; the sync worker has no listener) ---

resource "aws_lb" "api" {
  name               = "${var.project}-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project}-api"
  port        = var.api_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# HTTP listener redirects to HTTPS; HTTPS needs an ACM cert (CHECKLIST.md).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# --- Services ---

resource "aws_ecs_service" "api" {
  name             = "${var.project}-api"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.api.arn
  desired_count    = var.api_desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.api.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = var.api_container_port
  }

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "worker" {
  name            = "${var.project}-sync-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.worker.id]
  }
}
