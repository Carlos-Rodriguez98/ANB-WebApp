output "web_public_ip" {
  description = "Public IP of web server"
  value       = aws_instance.web.public_ip
}

output "worker_public_ip" {
  description = "Public IP of worker server"
  value       = aws_instance.worker.public_ip
}

output "fileserver_public_ip" {
  description = "Public IP of file server"
  value       = aws_instance.fileserver.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint (host)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "rds_identifier" {
  description = "RDS identifier"
  value       = aws_db_instance.postgres.id
}
