#!/bin/bash

## Add K8S repo

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

## Disable SeLinux

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

## Install K8S tools

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

## Add repo for CRI-O

export VERSION=1.24
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${VERSION}/CentOS_7/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo

## Install/start/enable CRI-O

sudo yum install -y cri-o tc vim wget
sudo systemctl enable --now crio

## Enable bridge netfilter

lsmod | grep br_netfilter
sudo modprobe br_netfilter
echo br_netfilter | sudo tee /etc/modules-load.d/br_netfilter.conf
lsmod | grep br_netfilter

## kernel para tuning

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

## set hostname
echo $(hostname -I) $(hostname) | sudo tee -a /etc/hosts

#Finally setup first control plane node

sudo kubeadm config images pull -v=1

sudo kubeadm init

