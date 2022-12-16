#!/bin/bash 

# turn swap off and comment out swap partition from fstab
swapoff -a
sed -e '/swap/ s/^#*/#/' -i /etc/fstab

# Update the system to the latest and greatest
apt-get update
apt-get upgrade -y

# Install a few extras, and remove nano
apt install wget vim sudo -y
apt remove nano -y

# add necessary kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter
sudo echo " 
overlay
br_netfilter" >> /etc/modules

# create a networking options file to enable whats needed and call sysctl to load it
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# install containerd and a few extras
wget https://github.com/containerd/containerd/releases/download/v1.6.12/containerd-1.6.12-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.6.12-linux-amd64.tar.gz

# install containerd.service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mkdir /usr/local/lib/systemd
mkdir /usr/local/lib/systemd/system
cp containerd.service /usr/local/lib/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd

# install containerd runc
wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

# install containerd cni
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

# edit containerd conf and enable SystemdCgroup 
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i s/SystemdCgroup\ \=\ false/SystemdCgroup\ \=\ true/g /etc/containerd/config.toml
systemctl restart containerd

# install k8s
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt upgrade

apt install -y kubelet kubeadm kubectl
# Enable use of the containerd unix socket
sed -i "s|KUBELET\_KUBECONFIG\_ARGS\=|KUBELET\_KUBECONFIG\_ARGS\=\-\-container\-runtime\-endpoint\=unix\:\/\/\/run\/containerd\/containerd\.sock\ |" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl restart  kubelet

# create the k8s config file
echo "apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  podSubnet: "10.244.0.0/16" # --pod-network-cidr" >> config.yaml

kubeadm init --config config.yaml
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml -o calico-custom-resources.yaml
sed -i "s|cidr: 192.168.0.0/16|cidr: 10.244.0.0/16|" calico-custom-resources.yaml
kubectl create -f  ./calico-custom-resources.yaml
kubectl taint node debian node-role.kubernetes.io/control-plane-

