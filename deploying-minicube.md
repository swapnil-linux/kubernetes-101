# Deploying Minicube

```
#!/bin/bash
yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
yum install vim git docker-ce docker-ce-cli conntrack epel-release tmux net-tools bash-completion wget -y

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
rpm -Uvh minikube-latest.x86_64.rpm

sysctl fs.protected_regular=0
setenforce 0
minikube delete --all
rm -rf .minikube .kube

minikube start --vm-driver=none

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/bin/kubectl

kubectl cluster-info
kubectl get nodes

```
