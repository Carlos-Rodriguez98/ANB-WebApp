#!/bin/bash
set -xe

yum update -y
yum install -y nfs-utils

# carpeta compartida
mkdir -p /srv/nfs/appfiles
chown nfsnobody:nfsnobody /srv/nfs/appfiles
chmod 777 /srv/nfs/appfiles

# habilita y configura NFS
echo "/srv/nfs/appfiles *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
systemctl enable nfs-server
systemctl start nfs-server
exportfs -rav
