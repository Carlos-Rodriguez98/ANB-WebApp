#!/bin/bash
set -xe

# Actualizar e instalar NFS
yum update -y
yum install -y nfs-utils

# Crear carpeta compartida
mkdir -p /srv/nfs/appfiles
chmod 777 /srv/nfs/appfiles

# Configurar puertos estáticos para NFS en Amazon Linux 2023
# Crear directorio de configuración si no existe
mkdir -p /etc/systemd/system/nfs-server.service.d

# Configurar puertos estáticos via systemd
cat > /etc/nfs.conf <<EOF
[mountd]
port=892

[statd]
port=662

[lockd]
port=32803
udp-port=32769
EOF

# Configurar exports - permitir solo redes privadas VPC
cat > /etc/exports <<EOF
/srv/nfs/appfiles 10.0.0.0/16(rw,sync,no_root_squash,no_subtree_check)
EOF

# Habilitar e iniciar rpcbind (necesario para NFS)
systemctl enable rpcbind
systemctl start rpcbind

# Habilitar e iniciar NFS server
systemctl enable nfs-server
systemctl start nfs-server

# Aplicar exports
exportfs -ra

# Verificar servicios
systemctl status rpcbind --no-pager
systemctl status nfs-server --no-pager

# Verificar exports
showmount -e localhost

echo "NFS server configurado y corriendo"
echo "Exports disponibles:"
exportfs -v
