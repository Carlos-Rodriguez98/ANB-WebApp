output "vpc_id"                 { value = aws_vpc.main.id }
output "public_subnet_id"       { value = aws_subnet.public.id }
output "private_subnet_a"       { value = aws_subnet.private_a.id }
output "private_subnet_b"       { value = aws_subnet.private_b.id }
output "public_route_table_id"  { value = aws_route_table.public.id }
output "private_route_table_id" { value = aws_route_table.private.id }

output "web_sg_id"    { value = aws_security_group.web.id }
output "worker_sg_id" { value = aws_security_group.worker.id }
output "nfs_sg_id"    { value = aws_security_group.nfs.id }
output "rds_sg_id"    { value = aws_security_group.rds.id }

output "web_public_ip"  { value = aws_instance.web.public_ip }
output "worker_private_ip" { value = aws_instance.worker.private_ip }
output "nfs_private_ip"    { value = aws_instance.nfs.private_ip }

output "rds_endpoint" { value = aws_db_instance.main.address }
output "rds_port"     { value = aws_db_instance.main.port }
output "rds_db_name"  { value = aws_db_instance.main.db_name }

output "web_instance_profile" { value = aws_iam_instance_profile.anbapp_ssm_profile.name }