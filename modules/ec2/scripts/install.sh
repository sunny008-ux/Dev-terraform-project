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

echo "[STEP 1] Disabling swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

echo "[STEP 2] Installing containerd..."
sudo apt-get update -y
sudo apt-get install -y containerd

echo "[STEP 2] Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[STEP 3] Installing Kubernetes packages..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[STEP 4] Enabling IPv4 forwarding..."
sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

sudo sysctl --system

echo "[STEP 5] Initializing Kubernetes control plane..."
sudo kubeadm init \
  --apiserver-advertise-address=${CONTROL_PLANE_PRIVATE_IP} \
  --pod-network-cidr=${POD_CIDR}

echo "[STEP 6] Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[STEP 7] Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

echo "============================================="
echo " Kubernetes Control Plane Setup Completed!"
echo "============================================="

echo ""
echo "Run:"
echo "kubectl get nodes"
echo ""

echo "Worker Join Command:"
sudo kubeadm token create --print-join-command
