#!/bin/bash

DEBIAN_FRONTEND=noninteractive
K3S_CONFIG_DIR=/etc/rancher/k3s
K3S_CONFIG_PATH=$K3S_CONFIG_DIR/k3s.yaml

apt-get update
apt-get install -y net-tools nmap 
snap install yq
/usr/sbin/netfilter-persistent stop
/usr/sbin/netfilter-persistent flush
systemctl stop netfilter-persistent.service
systemctl disable netfilter-persistent.service
echo "SystemMaxUse=100M" >> /etc/systemd/journald.conf
echo "SystemMaxFileSize=100M" >> /etc/systemd/journald.conf
systemctl restart systemd-journald

INSTANCE_PUBLIC_IP=$(curl https://ifconfig.me)
INSTANCE_PRIVATE_IP=$(hostname -I | awk '{print $1}')
if [[ "${k3s_master_host}" == "localhost" ]]; then
  echo "Cluster init"
  k3s_install_params=()
  k3s_install_params+=("--node-label ${k3s_node_label}")
  k3s_install_params+=("--disable-cloud-controller")
  k3s_install_params+=("--kubelet-arg=cloud-provider=external")
  k3s_install_params+=("--disable-helm-controller ")
  k3s_install_params+=("--disable-network-policy")
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
  cat $K3S_CONFIG_PATH | yq '.clusters[0].cluster.certificate-authority-data' > $K3S_CONFIG_DIR/server-certificate-authority-data
  cat $K3S_CONFIG_PATH | yq '.clusters[0].cluster.server' | awk -F"https://" '{print $2}' | awk -F":" '{print $1}' > $K3S_CONFIG_DIR/server-ip
  cat $K3S_CONFIG_PATH | yq '.clusters[0].cluster.server' | awk -F"https://" '{print $2}' | awk -F":" '{print $2}' > $K3S_CONFIG_DIR/server-port
  cat $K3S_CONFIG_PATH | yq '.users[0].user.client-certificate-data' >$K3S_CONFIG_DIR/client-certificate-data
  cat $K3S_CONFIG_PATH | yq '.users[0].user.client-key-data' > $K3S_CONFIG_DIR/client-key-data
  chmod 0600 -R $K3S_CONFIG_DIR
else
  echo "Cluster join"
  k3s_install_params=()
  k3s_install_params+=("--node-label ${k3s_node_label}")
  k3s_install_params+=("--kubelet-arg=cloud-provider=external")
  k3s_install_params+=("--node-ip $INSTANCE_PRIVATE_IP")
  INSTALL_PARAMS="$${k3s_install_params[*]}"
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_version} K3S_TOKEN=${k3s_token} K3S_URL=https://${k3s_master_host}:6443 sh -s - $INSTALL_PARAMS
fi
