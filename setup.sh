#!/bin/bash
yum install ansible -y
ansible-playbook setup.yml -i localhost,
minikube start --vm-driver=none
kubectl cluster-info
kubectl get nodes
