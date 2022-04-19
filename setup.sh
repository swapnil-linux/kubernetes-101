#!/bin/bash
yum install ansible -y
#ansible-playbook https://raw.githubusercontent.com/swapnil-linux/kubernetes-101/main/setup.yml -i localhost,
ansible-playbook setup.yml -i localhost,
minikube start --vm-driver=none
kubectl cluster-info
kubectl get nodes
