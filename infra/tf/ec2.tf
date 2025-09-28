# Web server
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = local.web_instance_name
    Role = "web"
  }
  # Uso de block user_data para instalar un servidor simple (ejemplo)
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -a -G docker ec2-user

              # Install Docker Compose
              sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              docker-compose version

              # Configurar montaje NFS desde el file server
              sudo yum install -y nfs-utils
              sudo mkdir -p /mnt/fileserver
              sudo mount -t nfs ${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver
              echo "${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver nfs defaults 0 0" | sudo tee -a /etc/fstab
              EOF
}

# Worker server
resource "aws_instance" "worker" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = local.worker_instance_name
    Role = "worker"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -a -G docker ec2-user

              # Install Docker Compose
              sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              docker-compose version

              # Configurar montaje NFS desde el file server
              sudo yum install -y nfs-utils
              sudo mkdir -p /mnt/fileserver
              sudo mount -t nfs ${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver
              echo "${aws_instance.fileserver.private_ip}:/srv/nfs /mnt/fileserver nfs defaults 0 0" | sudo tee -a /etc/fstab
              EOF
}

# File server (NFS) - se requiere configurar NFS en la instancia
resource "aws_instance" "fileserver" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

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
