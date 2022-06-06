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

9\. Now that our cluster node is UP and running, we can create our first Pod (which is basically a container), but before that verify if there is already any pod available on the minikube cluster:

```
[centos@minicube ~]$ kubectl get pods
No resources found in default namespace.
[centos@minicube ~]$ 
```

10\. Lets fire-up a pod

```
[centos@minicube ~]$ kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
deployment.apps/hello-minikube created
[centos@minicube ~]$
```

11\. Its up and running

```
[centos@minicube ~]$ kubectl get pods 
NAME                              READY   STATUS    RESTARTS   AGE
hello-minikube-7bc9d7884c-2s725   1/1     Running   0          77s
[centos@minicube ~]$ 
```

12\. Lets expose it as a service

```
[centos@minicube ~]$ kubectl expose deployment hello-minikube --type=NodePort --port=8080
service/hello-minikube exposed
[centos@minicube ~]$ 
```

```
[centos@minicube ~]$ kubectl get service
NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
hello-minikube   NodePort    10.110.159.230   <none>        8080:30502/TCP   37s
kubernetes       ClusterIP   10.96.0.1        <none>        443/TCP          14h
[centos@minicube ~]$ 
```

13\. Use the below command to get the URL of our simple web app running in a pod

```
[centos@minicube ~]$ minikube service hello-minikube --url
http://192.168.49.2:30502
[centos@minicube ~]$
```

14\. Use any browser or curl to access the application

```
[centos@minicube ~]$ curl http://192.168.49.2:30502
CLIENT VALUES:
client_address=172.17.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://192.168.49.2:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=192.168.49.2:30502
user-agent=curl/7.61.1
BODY:
-no body in request-[centos@minicube ~]$ 
```

15\. Add 2 more nodes to the minicube cluster

```
[centos@minicube ~]$ minikube node list
minikube	192.168.49.2
```

```
[centos@minicube ~]$ minikube node add
😄  Adding node m02 to cluster minikube
❗  Cluster was created without any CNI, adding a node to it might cause broken networking.
👍  Starting worker node minikube-m02 in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=2200MB) ...
🐳  Preparing Kubernetes v1.23.3 on Docker 20.10.12 ...
🔎  Verifying Kubernetes components...
🏄  Successfully added m02 to minikube!
[centos@minicube ~]$ 
```

```
[centos@minicube ~]$ minikube node add
😄  Adding node m03 to cluster minikube
👍  Starting worker node minikube-m03 in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=2200MB) ...
🐳  Preparing Kubernetes v1.23.3 on Docker 20.10.12 ...
🔎  Verifying Kubernetes components...
🏄  Successfully added m03 to minikube!
[centos@minicube ~]$ 
```

```
[centos@minicube ~]$ minikube node list
minikube	192.168.49.2
minikube-m02	192.168.49.3
minikube-m03	192.168.49.4
[centos@minicube ~]$
```

```
[centos@minicube ~]$ kubectl get nodes
NAME           STATUS   ROLES                  AGE     VERSION
minikube       Ready    control-plane,master   14h     v1.23.3
minikube-m02   Ready    <none>                 2m11s   v1.23.3
minikube-m03   Ready    <none>                 62s     v1.23.3
[centos@minicube ~]$
```

16\. Lets scale our deployment to multiple pods

```
[centos@minicube ~]$ kubectl get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
hello-minikube   1/1     1            1           11m
```

```
[centos@minicube ~]$ kubectl scale deployment hello-minikube --replicas=3
deployment.apps/hello-minikube scaled
[centos@minicube ~]$ 
```

```
[centos@minicube ~]$ kubectl get pods -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
hello-minikube-7bc9d7884c-2s725   1/1     Running   0          13m   172.17.0.3   minikube       <none>           <none>
hello-minikube-7bc9d7884c-l7p2t   1/1     Running   0          43s   172.17.0.2   minikube-m02   <none>           <none>
hello-minikube-7bc9d7884c-ldb7g   1/1     Running   0          43s   172.17.0.2   minikube-m03   <none>           <none>
[centos@minicube ~]$ 
```

{% hint style="info" %}
You can notice how the application is scaled among the 3 available nodes&#x20;
{% endhint %}

17\. CleanUp

```
[centos@minicube ~]$ kubectl delete deployment hello-minikube
deployment.apps "hello-minikube" deleted
```

```
[centos@minicube ~]$ kubectl delete service hello-minikube
service "hello-minikube" deleted
[centos@minicube ~]$ 
```

{% hint style="info" %}
_**Perform the below steps only if you will no longer use minikube in later exercises**_
{% endhint %}

```
[centos@minicube ~]$ minikube stop
✋  Stopping node "minikube"  ...
🛑  Powering off "minikube" via SSH ...
✋  Stopping node "minikube-m02"  ...
🛑  Powering off "minikube-m02" via SSH ...
✋  Stopping node "minikube-m03"  ...
🛑  Powering off "minikube-m03" via SSH ...
🛑  3 nodes stopped.
```

```
[centos@minicube ~]$ minikube delete --all
🔥  Deleting "minikube" in docker ...
🔥  Removing /home/centos/.minikube/machines/minikube ...
🔥  Removing /home/centos/.minikube/machines/minikube-m02 ...
🔥  Removing /home/centos/.minikube/machines/minikube-m03 ...
💀  Removed all traces of the "minikube" cluster.
🔥  Successfully deleted all profiles
[centos@minicube ~]$ 
```
