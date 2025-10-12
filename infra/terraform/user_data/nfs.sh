#!/bin/bash
set -xe

# Actualizar e instalar NFS
yum update -y
yum install -y nfs-utils

# Crear carpeta compartida
mkdir -p /srv/nfs/appfiles
chmod 777 /srv/nfs/appfiles

# Configurar exports
cat > /etc/exports <<EOF
/srv/nfs/appfiles *(rw,sync,no_root_squash,no_subtree_check)
EOF

# Habilitar e iniciar NFS server
systemctl enable nfs-server
systemctl start nfs-server

# Aplicar exports
exportfs -ra

# Verificar que esté corriendo
systemctl status nfs-server

echo "NFS server configurado y corriendo"
