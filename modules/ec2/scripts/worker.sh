#!/bin/bash
set -e

echo "============================================="
echo " Kubernetes Worker Node Installation"
echo " containerd + kubeadm"
echo "============================================="

K8S_VERSION="v1.30"

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

echo "============================================="
echo " Worker Node Setup Completed!"
echo "============================================="

echo ""
echo "Now run join command from control plane:"
echo "sudo kubeadm join <control-plane-ip>:6443 --token xxxx --discovery-token-ca-cert-hash sha256:xxxx"
echo ""
