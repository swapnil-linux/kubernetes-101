#!/bin/bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

##install cri-o

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8_Stream/devel:kubic:libcontainers:stable.repo


curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.24.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.24:/1.24.0/CentOS_8_Stream/devel:kubic:libcontainers:stable:cri-o:1.24:1.24.0.repo

yum install -y cri-o tc vim wget

systemctl enable crio
systemctl start crio



modprobe br_netfilter


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF


sysctl --system


echo $(hostname -I) $(hostname) >> /etc/hosts


kubeadm config images pull

kubeadm init

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

______


#kubeadm join 10.0.2.23:6443 --token f8qblj.0qnukq61ko4hczc3 \
#> --discovery-token-ca-cert-hash sha256:3d47c5c256b0928d6dc783ce7d98d35ee0693fde3f04bb999896ce13feeb3b13

#If you don't have the value of --discovery-token-ca-cert-hash, you can get it by running the following command chain on the control-plane node:

#openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der | openssl dgst -sha256 -hex


#kubeadm token create --print-join-command --ttl 1h

