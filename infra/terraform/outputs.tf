output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_id" { value = aws_subnet.public.id }
output "public_subnet_b_id" { value = aws_subnet.public_b.id }
output "private_subnet_a" { value = aws_subnet.private_a.id }
output "private_subnet_b" { value = aws_subnet.private_b.id }
output "public_route_table_id" { value = aws_route_table.public.id }
output "private_route_table_id" { value = aws_route_table.private.id }

output "web_sg_id" { value = aws_security_group.web.id }
output "alb_sg_id" { value = aws_security_group.alb.id }
output "worker_sg_id" { value = aws_security_group.worker.id }
output "rds_sg_id" { value = aws_security_group.rds.id }

#output "web_public_ip" { value = aws_instance.web.public_ip }
#output "web_instance_id" { value = aws_instance.web.id }
output "worker_private_ip" { value = aws_instance.worker.private_ip }
output "worker_instance_id" { value = aws_instance.worker.id }
output "s3_bucket_name" { value = aws_s3_bucket.storage.bucket }
output "s3_bucket_arn" { value = aws_s3_bucket.storage.arn }

output "rds_endpoint" { value = aws_db_instance.main.address }
output "rds_port" { value = aws_db_instance.main.port }
output "rds_db_name" { value = aws_db_instance.main.db_name }

output "web_instance_profile" { value = data.aws_iam_instance_profile.lab_instance_profile.name }

# Application Load Balancer
output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}
output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}
output "application_url" {
  description = "URL de acceso a la aplicación web vía ALB"
  value       = "http://${aws_lb.main.dns_name}"
}

# SQS Queues
output "sqs_queue_url" {
  description = "URL de la cola SQS para procesamiento de videos"
  value       = aws_sqs_queue.video_processing.url
}

output "sqs_queue_arn" {
  description = "ARN de la cola SQS"
  value       = aws_sqs_queue.video_processing.arn
}

output "sqs_dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.video_processing_dlq.url
}