# Step FunctionsがECSタスクを実行するためのIAMポリシー
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECRリポジトリの作成
resource "aws_ecr_repository" "elt_repo" {
  for_each             = var.usecases
  name                 = "${var.project_name}-${each.value}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ライフサイクルポリシー
resource "aws_ecr_lifecycle_policy" "elt_repo_policy" {
  for_each   = aws_ecr_repository.elt_repo
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep 'latest' tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 3 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECS Taskロール
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECS Taskロール用のポリシー
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

# ECS実行用ロール
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "elt" {
  name = "${var.project_name}-elt-cluster"
}

# Ingestion用のTask Definition
resource "aws_ecs_task_definition" "ingestion" {
  family                   = "${var.project_name}-ingestion"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-ingestion-container"
      image = "node:14" # TBD: 作成したイメージに置き換え
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-ingestion"
          awslogs-region        = "${var.region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Transform用のTask Definition
resource "aws_ecs_task_definition" "transform" {
  family                   = "${var.project_name}-transform"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-transform-container"
      image = "node:14" # TBD: 作成したイメージに置き換え
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-transform"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Step FunctionsがECSタスクを実行するためのIAMロール
resource "aws_iam_role" "elt_statemachine" {
  name = "${var.project_name}-elt-workflow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# AWS アカウント ID を取得するためのデータソース
data "aws_caller_identity" "current" {}

# Step Functions が ECS タスクを実行するための IAM ポリシー
resource "aws_iam_role_policy" "step_functions_ecs_policy" {
  name = "${var.project_name}-step-functions-ecs-policy"
  role = aws_iam_role.elt_statemachine.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"
      }
    ]
  })
}

# Step Functionsのステートマシン定義
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.project_name}-elt-workflow"
  role_arn = aws_iam_role.elt_statemachine.arn

  definition = jsonencode({
    StartAt = "CheckTargetDate"
    States = {
      CheckTargetDate = {
        Type = "Choice"
        Choices = [
          {
            Variable  = "$.target_date"
            IsPresent = true
            Next      = "PassExistingTargetDate"
          }
        ]
        Default = "ExtractDateFromContext"
      }
      PassExistingTargetDate = {
        Type = "Pass"
        Next = "Ingestion"
      }
      ExtractDateFromContext = {
        Type = "Pass"
        Parameters = {
          "target_date.$" = "States.ArrayGetItem(States.StringSplit($$.Execution.StartTime, 'T'), 0)"
        }
        Next = "Ingestion"
      }
      Ingestion = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.elt.arn
          TaskDefinition = aws_ecs_task_definition.ingestion.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = [var.private_subnet_id]
              AssignPublicIp = "DISABLED"
            }
          }
        }
        Next = "Transform"
      }
      Transform = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = aws_ecs_cluster.elt.arn
          TaskDefinition = aws_ecs_task_definition.transform.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = [var.private_subnet_id]
              AssignPublicIp = "DISABLED"
            }
          }
        }
        End = true
      }
    }
  })
}
