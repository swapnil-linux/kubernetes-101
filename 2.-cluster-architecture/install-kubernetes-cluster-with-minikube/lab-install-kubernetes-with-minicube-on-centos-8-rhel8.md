# Lab: Install Kubernetes with minicube on CentOS 8 / RHEL8

{% hint style="info" %}
This lab exercise assumes you already have a CentOS8 or RHEL8 system up and running with internet connectivity.
{% endhint %}

1. Configure yum repo for docker-ce.

```
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

> **Expected Output:**

`Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo`

2\. Install docker and some necessary tools

```
sudo yum install vim git docker-ce docker-ce-cli conntrack epel-release tmux net-tools bash-completion wget -y
```

> **Expected Output:**

```
$ sudo yum install vim git docker-ce docker-ce-cli conntrack epel-release tmux net-tools bash-completion wget -y
CentOS Stream 8 - AppStream                                                               13 MB/s |  22 MB     00:01    
CentOS Stream 8 - BaseOS                                                                 7.1 MB/s |  22 MB     00:03    
CentOS Stream 8 - Extras                                                                  31 kB/s |  18 kB     00:00    
Docker CE Stable - x86_64                                                                435 kB/s |  25 kB     00:00    
Dependencies resolved.
=========================================================================================================================
 Package                         Architecture Version                                       Repository              Size
=========================================================================================================================
Installing:
 bash-completion                 noarch       1:2.7-5.el8                                   baseos                 274 k
 conntrack-tools                 x86_64       1.4.4-10.el8                                  baseos                 204 k
 .....
 .....
 vim-common-2:8.0.1763-16.el8_5.12.x86_64                                                                               
 vim-enhanced-2:8.0.1763-16.el8_5.12.x86_64                                                                             
 vim-filesystem-2:8.0.1763-16.el8_5.12.noarch                                                                           
 wget-1.19.5-10.el8.x86_64                                                                                              

Complete!
[centos@minicube ~]$ 
```

3\. Download and install latest version of minicube

```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm
```

> **Expected Output:**

```
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 15.6M  100 15.6M    0     0  21.8M      0 --:--:-- --:--:-- --:--:-- 21.9M
[centos@minicube ~]$ sudo rpm -Uvh minikube-latest.x86_64.rpm
Verifying...                          ################################# [100%]
Preparing...                          ################################# [100%]
Updating / installing...
   1:minikube-1.25.2-0                ################################# [100%]
[centos@minicube ~]$ 
```

4\. `systemd` now enables the `fs.protected_regular` kernel parameters by default. This may break applications that share files in /tmp (or other sticky directories) among multiple user accounts. The protection may be disabled by setting `fs.protected_regular=0`

```
sysctl fs.protected_regular=0
```

5\. By Disabling the SElinux **all containers can easily access host filesystem**.

```
setenforce 0
```

6\. Add the current non-root user to docker group.

```
sudo usermod -aG docker $USER && newgrp docker
```

7\. minicube supports the below drivers, with this guide we will use docker.

```
--driver='': Driver is one of: virtualbox, vmwarefusion, kvm2, vmware, none, docker, podman, ssh (defaults to
auto-detect)
```

```
minikube start --vm-driver=docker
```

> **Expected** **Output**:

```
[centos@minicube ~]$ minikube start --vm-driver=docker
😄  minikube v1.25.2 on Centos 8
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.23.3 preload ...
    > preloaded-images-k8s-v17-v1...: 505.68 MiB / 505.68 MiB  100.00% 113.70 M
    > gcr.io/k8s-minikube/kicbase: 379.06 MiB / 379.06 MiB  100.00% 10.06 MiB p
🔥  Creating docker container (CPUs=2, Memory=2200MB) ...
🐳  Preparing Kubernetes v1.23.3 on Docker 20.10.12 ...
    ▪ kubelet.housekeeping-interval=5m
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: default-storageclass, storage-provisioner
💡  kubectl not found. If you need it, try: 'minikube kubectl -- get pods -A'
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
[centos@minicube ~]$ 
```

```
[centos@minicube ~]$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

8\. Install kubectl and verify installtion

```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

```
sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl
```

```
$ kubectl version --short
Client Version: v1.24.1
Kustomize Version: v4.5.4
Server Version: v1.23.3
[centos@minicube ~]$ 
```

```
[centos@minicube ~]$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[centos@minicube ~]$ 

```

```
[centos@minicube ~]$ kubectl get nodes -o wide
NAME       STATUS   ROLES                  AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION              CONTAINER-RUNTIME
minikube   Ready    control-plane,master   6m27s   v1.23.3   192.168.49.2   <none>        Ubuntu 20.04.2 LTS   4.18.0-305.3.1.el8.x86_64   docker://20.10.12
[centos@minicube ~]$ 
```

