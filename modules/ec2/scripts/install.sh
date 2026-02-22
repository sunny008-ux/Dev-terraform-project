#!/bin/bash
set -e

echo "============================================="
echo " Kubernetes Control Plane Installation"
echo " containerd + kubeadm + Calico"
echo "============================================="

POD_CIDR="192.168.0.0/16"
K8S_VERSION="v1.30"

echo "[INFO] Fetching EC2 Private IP from Instance Metadata (IMDSv2)..."

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

CONTROL_PLANE_PRIVATE_IP=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

echo "[INFO] Detected CONTROL_PLANE_PRIVATE_IP: $CONTROL_PLANE_PRIVATE_IP"

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

curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
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
# Initialize Cluster
# -------------------------------
kubeadm init \
  --apiserver-advertise-address=${CONTROL_PLANE_PRIVATE_IP} \
  --pod-network-cidr=${POD_CIDR}

# -------------------------------
# Configure kubectl for ubuntu user
# -------------------------------
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# -------------------------------
# Install Calico CNI
# -------------------------------
su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml"

# -------------------------------
# Generate Worker Join Script
# -------------------------------
kubeadm token create --print-join-command > /home/ubuntu/join.sh
chmod +x /home/ubuntu/join.sh
chown ubuntu:ubuntu /home/ubuntu/join.sh

echo "============================================="
echo " Kubernetes Control Plane Setup Completed!"
echo " Join command saved to /home/ubuntu/join.sh"
echo "============================================="