#!/bin/bash

DEBIAN_FRONTEND=noninteractive
K3S_CONFIG_DIR=/etc/rancher/k3s
K3S_CONFIG_PATH=$K3S_CONFIG_DIR/k3s.yaml

apt update && apt install -y \
    jq \
    net-tools \
    nmap 

/usr/sbin/netfilter-persistent stop
/usr/sbin/netfilter-persistent flush
systemctl stop netfilter-persistent.service
systemctl disable netfilter-persistent.service
echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
echo "SystemMaxFileSize=100M" >> /etc/systemd/journald.conf
systemctl restart systemd-journald

INSTANCE_PUBLIC_IP=$(curl ifconfig.me)
INSTANCE_PRIVATE_IP=$(hostname -I | awk '{print $1}')
INSTANCE_OCID=$(curl -sH "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | jq -r '.id')

if [[ "${k3s_master_host}" == "localhost" ]]; then
  echo "Cluster init"
  k3s_install_params=()
  k3s_install_params+=("--disable-cloud-controller")
  k3s_install_params+=("--kubelet-arg=cloud-provider=external")
  k3s_install_params+=("--kubelet-arg=provider-id=$INSTANCE_OCID")
  k3s_install_params+=("--disable-helm-controller ")
  k3s_install_params+=("--disable servicelb")
  k3s_install_params+=("--disable traefik")
  k3s_install_params+=("--tls-san $INSTANCE_PUBLIC_IP")
  INSTALL_PARAMS="$${k3s_install_params[*]}"
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_version} K3S_TOKEN=${k3s_token} sh -s - --cluster-init $INSTALL_PARAMS
  until kubectl get pods -n kube-system | grep -E 'Pending|Running'; do
    echo 'Waiting for k3s'
    sleep 5
  done
  echo "K3s running and waiting for oci-cloud-controller-manager to be installed"
  sed -i "s/127\.0\.0\.1/$INSTANCE_PUBLIC_IP/g" $K3S_CONFIG_PATH
  cat $K3S_CONFIG_PATH | grep 'certificate-authority-data' | awk '{print $2}' > $K3S_CONFIG_DIR/certificate-authority-data
  cat $K3S_CONFIG_PATH | grep 'server' | awk '{print $2}' | awk -F"https://" '{print $2}' | awk -F":" '{print $1}' > $K3S_CONFIG_DIR/server
  cat $K3S_CONFIG_PATH | grep 'server' | awk -F"https://" '{print $2}' | awk -F":" '{print $2}' > $K3S_CONFIG_DIR/port
  cat $K3S_CONFIG_PATH | grep 'client-certificate-data' | awk '{print $2}' > $K3S_CONFIG_DIR/client-certificate-data
  cat $K3S_CONFIG_PATH | grep 'client-key-data' | awk '{print $2}' > $K3S_CONFIG_DIR/client-key-data
  chmod 0600 -R $K3S_CONFIG_DIR
else
  echo "Cluster join"
  k3s_install_params=()
  k3s_install_params+=("--kubelet-arg=cloud-provider=external")
  k3s_install_params+=("--kubelet-arg=provider-id=$INSTANCE_OCID")
  k3s_install_params+=("--node-ip $INSTANCE_PRIVATE_IP")
  INSTALL_PARAMS="$${k3s_install_params[*]}"
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_version} K3S_TOKEN=${k3s_token} K3S_URL=https://${k3s_master_host}:6443 sh -s - $INSTALL_PARAMS
fi
