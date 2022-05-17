#!/bin/bash

# Based on https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
# Based on https://linuxconfig.org/quick-nfs-server-configuration-on-redhat-7-linux

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Create NFS StorageClass install started"

echo
echo ">>>>Init env"
PATH=$PATH:/usr/local/bin
. ../init.sh

echo
echo ">>>>$(print_timestamp) Install and expose NFS"
yum install -y nfs-utils rpcbind
mkdir -p /nfs
chmod -R 777 /nfs

# Add following line so that any host has access to NFS, in reality that would be at least all OCP nodes.  
# Setting *no_root_squash* wouldn't be used in real world implementations as it is insecure.
echo '/nfs *(no_subtree_check,rw,sync,no_wdelay,no_root_squash,no_all_squash)' >> /etc/exports

exportfs -a
firewall-cmd --zone=public --add-port=2049/tcp --permanent
firewall-cmd --zone=public --add-port=20048/tcp --permanent
firewall-cmd --zone=public --add-port=111/tcp --permanent
firewall-cmd --reload
service rpcbind start; service nfs-server start
# needed to sudo reboot
systemctl enable nfs-server

echo
echo ">>>>$(print_timestamp) Configure NFS Provisioner in OCP"
mkdir -p /nfs/storage
chmod -R 777 /nfs/storage
oc new-project nfs-client-provisioner
oc apply -f rbac.yaml
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:nfs-client-provisioner:nfs-client-provisioner
sed -f - deployment.yaml > deployment.target.yaml << SED_SCRIPT
s|{{NFS_HOSTNAME}}|${NFS_HOSTNAME}|g
SED_SCRIPT

oc apply -f deployment.target.yaml
oc apply -f storageclass.yaml

echo
echo ">>>>$(print_timestamp) Create NFS StorageClass install completed"
