# Cola SQS para procesamiento de videos
resource "aws_sqs_queue" "video_processing" {
  name                       = "${var.project_name}-video-processing"
  delay_seconds              = 0
  max_message_size           = 262144  # 256 KB
  message_retention_seconds  = 1209600 # 14 días
  receive_wait_time_seconds  = 10      # Long polling
  visibility_timeout_seconds = 1800    # 30 minutos (tiempo máximo de procesamiento)

  tags = {
    Name    = "${var.project_name}-video-queue"
    Project = var.project_name
  }
}

# Dead Letter Queue para mensajes fallidos
resource "aws_sqs_queue" "video_processing_dlq" {
  name                      = "${var.project_name}-video-processing-dlq"
  message_retention_seconds = 1209600 # 14 días

  tags = {
    Name    = "${var.project_name}-video-dlq"
    Project = var.project_name
  }
}

# Redrive policy: después de 3 intentos fallidos, mover a DLQ
resource "aws_sqs_queue_redrive_policy" "video_processing" {
  queue_url = aws_sqs_queue.video_processing.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.video_processing_dlq.arn
    maxReceiveCount     = 3
  })
}
