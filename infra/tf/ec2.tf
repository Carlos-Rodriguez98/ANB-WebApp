# Web server
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = local.web_instance_name
    Role = "web"
  }

  connection {
	type        = "ssh"
	user        = "ec2-user"
	private_key = file(var.ssh_private_key_path)
	host        = self.public_ip
  }

  provisioner "file" {
	source = "../docker-compose-web.yml"
	destination = "/home/ec2-user/docker-compose.yml"
  }

  provisioner "file" {
	source = "../.env"
	destination = "/home/ec2-user/.env"
  }

  provisioner "file" {
	source = "../../services/auth-service"
	destination = "/home/ec2-user/auth-service"
  }

  provisioner "file" {
	source = "../../services/front"
	destination = "/home/ec2-user/front"
  }

  provisioner "file" {
	source = "../../services/ranking-service"
	destination = "/home/ec2-user/ranking-service"
  }

  provisioner "file" {
	source = "../../services/voting-service"
	destination = "/home/ec2-user/voting-service"
  }

  provisioner "file" {
    source = "../init.sql"
    destination = "/home/ec2-user/init.sql"
  }

  provisioner "remote-exec" {
	inline = [
		"sudo yum update -y",
		"sudo yum install -y docker",
		"sudo systemctl enable docker",
		"sudo systemctl start docker",
		"sudo usermod -a -G docker ec2-user",
		"sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
		"sudo chmod +x /usr/local/bin/docker-compose",
		"docker-compose version",
		"sudo yum install -y nfs-utils",
		"sudo mkdir -p /mnt/fileserver",
		"sudo mount -t nfs ${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver",
		"echo '${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver nfs defaults 0 0' | sudo tee -a /etc/fstab",
		"sudo docker-compose -f /home/ec2-user/docker-compose.yml up -d",
		"sudo yum install -y nginx",
		"sudo systemctl enable nginx",
		"sudo systemctl start nginx",
		"echo 'server {\n    listen 80;\n    server_name _;\n    location / {\n        proxy_pass http://localhost:8084;\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto $scheme;\n    }\n    location /auth/ {\n        proxy_pass http://localhost:8080/;\n    }\n    location /ranking/ {\n        proxy_pass http://localhost:8083/;\n    }\n    location /voting/ {\n        proxy_pass http://localhost:8082/;\n    }\n}' | sudo tee /etc/nginx/conf.d/app.conf",
		"sudo systemctl restart nginx",
    "sudo yum install -y postgresql",
    "until PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.endpoint} -U ${var.db_username} -d ${var.db_name} -c '\\q'; do echo 'Waiting for RDS...'; sleep 5; done",
    "PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.endpoint} -U ${var.db_username} -d ${var.db_name} -f /home/ec2-user/init.sql"
	]
  }

  # Uso de block user_data para instalar un servidor
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo yum update -y
#               sudo yum install -y docker
#               sudo systemctl enable docker
#               sudo systemctl start docker
#               sudo usermod -a -G docker ec2-user

#               # Install Docker Compose
#               sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
#               sudo chmod +x /usr/local/bin/docker-compose
#               docker-compose version

#               # Configurar montaje NFS desde el file server
#               sudo yum install -y nfs-utils
#               sudo mkdir -p /mnt/fileserver
#               sudo mount -t nfs ${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver
#               echo "${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver nfs defaults 0 0" | sudo tee -a /etc/fstab
#               EOF
}

# Worker server
resource "aws_instance" "worker" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = local.worker_instance_name
    Role = "worker"
  }

  connection {
	type        = "ssh"
	user        = "ec2-user"
	private_key = file(var.ssh_private_key_path)
	host        = self.public_ip
  }

  provisioner "file" {
	source = "../docker-compose-worker.yml"
	destination = "/home/ec2-user/docker-compose.yml"
  }

  provisioner "file" {
	source = "../.env"
	destination = "/home/ec2-user/.env"
  }

  provisioner "file" {
	source = "../../services/processing-service"
	destination = "/home/ec2-user/processing-service"
  }

  provisioner "file" {
	source = "../../services/video-service"
	destination = "/home/ec2-user/video-service"
  }

  provisioner "remote-exec" {
	inline = [
		"sudo yum update -y",
		"sudo yum install -y docker",
		"sudo systemctl enable docker",
		"sudo systemctl start docker",
		"sudo usermod -a -G docker ec2-user",
		"sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
		"sudo chmod +x /usr/local/bin/docker-compose",
		"docker-compose version",
		"sudo yum install -y nfs-utils",
		"sudo mkdir -p /mnt/fileserver",
		"sudo mount -t nfs ${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver",
		"echo '${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver nfs defaults 0 0' | sudo tee -a /etc/fstab",
		"sudo docker-compose -f /home/ec2-user/docker-compose.yml up -d"
	]
  }

#   user_data = <<-EOF
#               #!/bin/bash
#               sudo yum update -y
#               sudo yum install -y docker
#               sudo systemctl enable docker
#               sudo systemctl start docker
#               sudo usermod -a -G docker ec2-user

#               # Install Docker Compose
#               sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
#               sudo chmod +x /usr/local/bin/docker-compose
#               docker-compose version

#               # Configurar montaje NFS desde el file server
#               sudo yum install -y nfs-utils
#               sudo mkdir -p /mnt/fileserver
#               sudo mount -t nfs ${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver
#               echo "${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver nfs defaults 0 0" | sudo tee -a /etc/fstab
#               EOF
}

# File server (NFS) - se requiere configurar NFS en la instancia
resource "aws_instance" "fileserver" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = local.fileserver_instance_name
    Role = "fileserver"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nfs-utils
              # Crear y exportar directorio NFS (ejemplo simple)
              mkdir -p /srv/nfs
              chown nobody:nobody /srv/nfs
              chmod 777 /srv/nfs
              echo "/srv/nfs *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
              systemctl enable rpcbind nfs-server
              systemctl start rpcbind nfs-server
              exportfs -a
              EOF
}
