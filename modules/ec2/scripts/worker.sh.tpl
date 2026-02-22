#!/bin/bash
set -e

echo "============================================="
echo " Kubernetes Worker Node Installation"
echo " containerd + kubeadm + Auto Join"
echo "============================================="

K8S_VERSION="v1.30"

# Get master private IP dynamically from metadata (if needed later)
# For now we pass it via Terraform templatefile
MASTER_PRIVATE_IP="${master_ip}"

echo "[INFO] Master Private IP: $MASTER_PRIVATE_IP"

# -------------------------------
# Disable Swap
# -------------------------------
swapoff -a
sed -i '/swap/d' /etc/fstab

# -------------------------------
# Install containerd
# -------------------------------
apt-get update -y
apt-get install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# -------------------------------
# Install Kubernetes
# -------------------------------
apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# -------------------------------
# Enable Networking
# -------------------------------
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

sysctl --system

# -------------------------------
# Wait for Master to be Ready
# -------------------------------
echo "[INFO] Waiting for master to generate join command..."
sleep 90

# -------------------------------
# Fetch Join Script from Master
# -------------------------------
ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_PRIVATE_IP "cat /home/ubuntu/join.sh" > /tmp/join.sh

chmod +x /tmp/join.sh

echo "[INFO] Joining cluster..."
bash /tmp/join.sh

echo "============================================="
echo " Worker Successfully Joined the Cluster!"
echo "============================================="