resource "aws_s3_bucket" "storage" {
  bucket = "${var.project_name}-video-storage${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-storage"
    Project = var.project_name
  }
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}