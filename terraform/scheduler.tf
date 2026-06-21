# ──────────────────────────────────────────────────────────────
# 운영시간 자동 전원 제어 (KST 09~21시)
#   EventBridge Scheduler(Asia/Seoul) → Lambda → EC2/RDS start·stop
#   - start: 08:40 (RDS 기동 여유 + EC2 부팅 시간 확보)
#   - stop : 21:00
# EventBridge Scheduler 는 타임존을 직접 지원해 UTC 환산 불필요.
# ──────────────────────────────────────────────────────────────

data "archive_file" "power" {
  type        = "zip"
  source_file = "${path.module}/lambda/power.py"
  output_path = "${path.module}/lambda/power.zip"
}

# ── Lambda 실행 역할 ──
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_power" {
  count              = var.enable_scheduler ? 1 : 0
  name               = "${var.project_name}-lambda-power"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda_power" {
  count = var.enable_scheduler ? 1 : 0
  name  = "power"
  role  = aws_iam_role.lambda_power[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:StartInstances", "ec2:StopInstances", "ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["rds:StartDBInstance", "rds:StopDBInstance", "rds:DescribeDBInstances"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_lambda_function" "power" {
  count            = var.enable_scheduler ? 1 : 0
  function_name    = "${var.project_name}-power"
  role             = aws_iam_role.lambda_power[0].arn
  handler          = "power.handler"
  runtime          = "python3.12"
  timeout          = 60
  filename         = data.archive_file.power.output_path
  source_code_hash = data.archive_file.power.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID    = aws_instance.app.id
      DB_INSTANCE_ID = aws_db_instance.main.identifier
    }
  }
}

# ── EventBridge Scheduler 가 Lambda 호출할 역할 ──
data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  count              = var.enable_scheduler ? 1 : 0
  name               = "${var.project_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  count = var.enable_scheduler ? 1 : 0
  name  = "invoke-lambda"
  role  = aws_iam_role.scheduler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.power[0].arn
    }]
  })
}

resource "aws_scheduler_schedule" "start" {
  count = var.enable_scheduler ? 1 : 0
  name  = "${var.project_name}-start"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.start_schedule_cron
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.power[0].arn
    role_arn = aws_iam_role.scheduler[0].arn
    input    = jsonencode({ action = "start" })
  }
}

resource "aws_scheduler_schedule" "stop" {
  count = var.enable_scheduler ? 1 : 0
  name  = "${var.project_name}-stop"

  flexible_time_window { mode = "OFF" }
  schedule_expression          = var.stop_schedule_cron
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.power[0].arn
    role_arn = aws_iam_role.scheduler[0].arn
    input    = jsonencode({ action = "stop" })
  }
}
