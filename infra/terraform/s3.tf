# Almacenamiento de los videos originales y procesados
resource "aws_s3_bucket" "video_uploads" {
  bucket        = "anbapp-uploads-bucket"
  force_destroy = true
}

resource "aws_s3_bucket" "video_processed" {
  bucket        = "${var.project_name}-videos-procesados"
  force_destroy = true
}