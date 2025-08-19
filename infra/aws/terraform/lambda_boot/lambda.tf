data "archive_file" "bootstrap_zip" {
  type        = "zip"
  source_file = "${path.module}/../../bootstrap_lambda/handler.py"
  output_path = "${path.module}/bootstrap-handler.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.env}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-${var.env}-api"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.bootstrap_zip.output_path
  source_code_hash = data.archive_file.bootstrap_zip.output_base64sha256

  # Attach to the same VPC private subnets & Lambda SG from Root 1
  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    security_group_ids = [data.terraform_remote_state.vpc.outputs.lambda_sg_id]
  }

  environment {
    variables = { APP_ENV = var.env }
  }

  tags = { Project = var.project_name, Env = var.env }
}

output "lambda_name" { value = aws_lambda_function.api.function_name }
output "lambda_arn" { value = aws_lambda_function.api.arn }
output "lambda_invoke_arn" { value = aws_lambda_function.api.invoke_arn }