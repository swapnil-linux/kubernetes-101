# Optional Lab: Adding nodes to the cluster

{% hint style="info" %}
* This lab exercise will require additional linux systems.
* Make sure all systems are able to resolve hostnames either by using DNS or `/etc/hosts` file
{% endhint %}

1. Follow steps 1 to 9 from the previous lab on all the additional node.

{% code title="COMMAND" %}
```bash
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

## IF USING RHEL 7 MAKE SURE extras repo is enabled
subscription-manager repos --enable rhel-7-server-extras-rpms



export VERSION=1.24
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${VERSION}/CentOS_7/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo

## Install/start/enable CRI-O

sudo yum install -y cri-o tc vim wget

## Change Driver to vfs for RHEL 7

sudo sed -i 's/driver = "overlay"/driver = "vfs"/g' /etc/containers/storage.conf
sudo sed -i 's/# storage_driver = "vfs"/storage_driver = "vfs"/g' /etc/crio/crio.conf


sudo systemctl enable --now crio

## Enable bridge netfilter

lsmod | grep br_netfilter
sudo modprobe br_netfilter
echo br_netfilter | sudo tee /etc/modules-load.d/br_netfilter.conf
lsmod | grep br_netfilter

## kernel parameters

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```
{% endcode %}

2\. List the existing tokens on the control plane node

{% code title="COMMAND" %}
```
sudo kubeadm token list
```
{% endcode %}

3\. Generate a new token with a short TTL which we will use to join our nodes to the cluster.

{% code title="COMMAND" %}
```
sudo kubeadm token create --print-join-command --ttl 60m 
```
{% endcode %}

{% code title="OUTPUT" %}
```
[centos@ip-10-0-2-94 ~]$ sudo kubeadm token create --print-join-command --ttl 60m
kubeadm join 10.0.2.94:6443 --token 71oeqm.nh69zj2pzwhzoabq --discovery-token-ca-cert-hash sha256:2cd25f812a5a5a1fd87aa31cf548d04f44a1f9d44b24b64878f32ef688bc948c 
```
{% endcode %}

{% code title="COMMAND" %}
```
sudo kubeadm token list
```
{% endcode %}

{% code title="OUTPUT" %}
```
[centos@ip-10-0-2-94 ~]$ sudo kubeadm token list
TOKEN                     TTL         EXPIRES                USAGES                   DESCRIPTION                                                EXTRA GROUPS
71oeqm.nh69zj2pzwhzoabq   56m         2022-07-03T02:09:15Z   authentication,signing   <none>                                                     system:bootstrappers:kubeadm:default-node-token
b57zm1.y21874qrg3ybca94   23h         2022-07-04T01:07:21Z   authentication,signing   <none>                                                     system:bootstrappers:kubeadm:default-node-token
```
{% endcode %}

4\. Copy the join command and paste it on all nodes.

{% code title="COMMAND" %}
```
sudo kubeadm join 10.0.2.94:6443 --token 71oeqm.nh69zj2pzwhzoabq --discovery-token-ca-cert-hash sha256:2cd25f812a5a5a1fd87aa31cf548d04f44a1f9d44b24b64878f32ef688bc948c 
```
{% endcode %}



{% code title="OUTPUT" %}
```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

[centos@ip-10-0-2-184 ~]$ 
```
{% endcode %}

5\. To verify the nodes were successfully joined run the below commands

{% code title="COMMAND" %}
```
kubectl get nodes
```
{% endcode %}

{% code title="OUTPUT" %}
```
[centos@ip-10-0-2-94 ~]$ kubectl get nodes
NAME                                            STATUS   ROLES           AGE     VERSION
ip-10-0-2-184.ap-southeast-2.compute.internal   Ready    <none>          2m12s   v1.24.2
ip-10-0-2-77.ap-southeast-2.compute.internal    Ready    <none>          43s     v1.24.2
ip-10-0-2-94.ap-southeast-2.compute.internal    Ready    control-plane   6d14h   v1.24.2
```
{% endcode %}

{% code title="COMMAND" %}
```
kubectl get pods --all-namespaces  -o wide
```
{% endcode %}

{% code title="OUTPUT" %}
```
[centos@ip-10-0-2-94 ~]$ kubectl get pods --all-namespaces  -o wide
NAMESPACE     NAME                                                                   READY   STATUS    RESTARTS   AGE     IP            NODE                                            NOMINATED NODE   READINESS GATES
kube-system   calico-kube-controllers-6766647d54-vxt5v                               1/1     Running   0          6d14h   10.244.44.1   ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   calico-node-lcv49                                                      1/1     Running   0          6d14h   10.0.2.94     ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   calico-node-t596c                                                      1/1     Running   0          2m11s   10.0.2.77     ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
kube-system   calico-node-wgrqv                                                      1/1     Running   0          3m40s   10.0.2.184    ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
kube-system   coredns-6d4b75cb6d-gbc9x                                               1/1     Running   0          6d14h   10.244.44.2   ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   coredns-6d4b75cb6d-j2dr7                                               1/1     Running   0          6d14h   10.244.44.3   ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   etcd-ip-10-0-2-94.ap-southeast-2.compute.internal                      1/1     Running   4          6d14h   10.0.2.94     ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   kube-apiserver-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          6d14h   10.0.2.94     ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   kube-controller-manager-ip-10-0-2-94.ap-southeast-2.compute.internal   1/1     Running   0          6d14h   10.0.2.94     ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   kube-proxy-8bppf                                                       1/1     Running   0          6d14h   10.0.2.94     ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
kube-system   kube-proxy-kt9wp                                                       1/1     Running   0          3m40s   10.0.2.184    ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
kube-system   kube-proxy-mvf27                                                       1/1     Running   0          2m11s   10.0.2.77     ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
kube-system   kube-scheduler-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   4          6d14h   10.0.2.94     ip-10-0-2-94.ap-southeast-2.compute.internal    <none>           <none>
[centos@ip-10-0-2-94 ~]$ 

```
{% endcode %}

6\. A node role is just a label, assign role worker to the new nodes. This is an optional step.

{% code title="COMMAND" %}
```
kubectl label nodes ip-10-0-2-77.ap-southeast-2.compute.internal node-role.kubernetes.io/worker=
```
{% endcode %}

{% code title="OUTPUT" %}
```
[centos@ip-10-0-2-94 ~]$ kubectl label nodes ip-10-0-2-184.ap-southeast-2.compute.internal node-role.kubernetes.io/worker=
node/ip-10-0-2-184.ap-southeast-2.compute.internal labeled
```
{% endcode %}

{% code title="COMMAND" %}
```bash
kubectl get nodes
```
{% endcode %}

{% code title="OUTPUT" %}
```
[centos@ip-10-0-2-94 ~]$ kubectl get nodes
NAME                                            STATUS   ROLES           AGE     VERSION
ip-10-0-2-184.ap-southeast-2.compute.internal   Ready    worker          9m17s   v1.24.2
ip-10-0-2-77.ap-southeast-2.compute.internal    Ready    worker          7m48s   v1.24.2
ip-10-0-2-94.ap-southeast-2.compute.internal    Ready    control-plane   6d14h   v1.24.2
```
{% endcode %}

{% hint style="info" %}
You can choose your node to have any role like `node-role.kubernetes.io/testing=` and `node-role.kubernetes.io/dev=`... The column ROLES will display the value(s) separated by comma in case multiple values exist&#x20;
{% endhint %}

**tada** :tada:
