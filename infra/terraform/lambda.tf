data "external" "build_lambda" {
  program = [
    "bash",
    "-c",
    "cd ${path.module}/../../services/processing-service-lambda/ && go mod tidy && env GOOS=linux GOARCH=arm64 go build -o bootstrap . && echo '{\"build\":\"ok\"}'"
  ]
}

############################################
# ARCHIVO ZIP COMPILADO DE GO
############################################

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../services/processing-service-lambda/bootstrap"
  output_path = "${path.module}/../../services/processing-service-lambda/lambda.zip"
  depends_on  = [data.external.build_lambda]
}

############################################
# LAMBDA FUNCTION (GO)
############################################

resource "aws_lambda_function" "worker_lambda" {
  function_name = "${var.project_name}-worker-lambda"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "provided.al2"
  handler = "bootstrap"
  architectures    = ["arm64"]
  timeout = 300
  memory_size = 2048

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST        = aws_db_instance.main.address
      DB_PORT        = var.db_port
      DB_USER        = var.db_username
      DB_PASSWORD    = var.db_password
      DB_NAME        = var.db_name
      DB_SSLMODE     = "require"
      JWT_SECRET     = var.jwt_secret
      S3_BUCKET_NAME = aws_s3_bucket.storage.id
      SQS_QUEUE_URL  = aws_sqs_queue.video_processing.url
      SSM_BASE_PATH  = var.ssm_path
    }
  }

  role = data.aws_iam_role.lab_role.arn

  depends_on = [
    data.archive_file.lambda_zip,
  ]
}

############################################
# PERMISO SQS → LAMBDA
############################################
resource "aws_lambda_permission" "allow_sqs" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.worker_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.video_processing.arn
}

############################################
# EVENT SOURCE MAPPING (SQS → LAMBDA)
############################################
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = aws_sqs_queue.video_processing.arn
  function_name    = aws_lambda_function.worker_lambda.arn
  batch_size       = 1
}