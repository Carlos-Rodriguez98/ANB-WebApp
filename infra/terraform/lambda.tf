data "external" "build_lambda" {
  program = ["bash", "-c", "cd ../../worker_lambda && go mod tidy && env GOOS=linux GOARCH=arm64 go build -o bootstrap . && echo '{\"filename\":\"bootstrap\"}'"]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../worker_lambda/bootstrap"
  output_path = "${path.module}/lambda_function.zip"
  depends_on  = [data.external.build_lambda]
}

resource "aws_lambda_function" "worker_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-worker-lambda"
  role             = "arn:aws:iam::562172447402:role/LabRole" # data.aws_iam_instance_profile.lab_instance_profile.name
 
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["arm64"]
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

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
      # AWS_REGION     = var.aws_region
      SQS_QUEUE_URL  = aws_sqs_queue.video_processing.url
      SSM_BASE_PATH  = var.ssm_path
    }
  }

  depends_on = [
    data.archive_file.lambda_zip,
    # aws_iam_role_policy_attachment.lambda_worker_custom_attachment,
    # aws_iam_role_policy_attachment.lambda_basic_execution_attachment,
    # aws_iam_role_policy_attachment.lambda_vpc_attachment
  ]
}

resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = aws_sqs_queue.video_processing.arn
  function_name    = aws_lambda_function.worker_lambda.arn
  batch_size       = 5
}

# resource "aws_iam_role" "lambda_exec_role" {
#   name = "${var.project_name}-lambda-exec-role"

#   assume_role_policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [{
#       Action    = "sts:AssumeRole",
#       Effect    = "Allow",
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#     }]
#   })

#   tags = {
#     Name = "${var.project_name}-lambda-exec-role"
#   }
# }

# resource "aws_iam_policy" "lambda_worker_policy" {
#   name        = "${var.project_name}-lambda-worker-policy"
#   description = "IAM policy for Lambda worker to access S3, SQS, and SSM"

#   policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [
#       {
#         Action   = ["s3:GetObject", "s3:PutObject"],
#         Effect   = "Allow",
#         Resource = "${aws_s3_bucket.storage.arn}/*"
#       },
#       {
#         Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
#         Effect   = "Allow",
#         Resource = aws_sqs_queue.video_processing.arn
#       },
#       {
#         Action   = ["ssm:GetParametersByPath"],
#         Effect   = "Allow",
#         Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.ssm_path}"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_worker_custom_attachment" {
#   role       = aws_iam_role.lambda_exec_role.name
#   policy_arn = aws_iam_policy.lambda_worker_policy.arn
# }

# resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attachment" {
#   role       = aws_iam_role.lambda_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_iam_role_policy_attachment" "lambda_vpc_attachment" {
#   role       = aws_iam_role.lambda_exec_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
# }
