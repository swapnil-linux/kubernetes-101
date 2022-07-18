# Lab: Installing kubernetes cluster using kubeadm

1. Configure kubernetes repo

{% code title="COMMAND" %}
```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```
{% endcode %}

2\. Set SELinux in permissive mode (effectively disabling it)

{% code title="COMMAND" %}
```bash
sudo setenforce 0
```
{% endcode %}

{% code title="COMMAND" %}
```
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```
{% endcode %}

3\. Install kubelet (a kubernetes agent), kubeadm (kubernetes install tool) and kubectl (kubernetes CLI)

{% code title="COMMAND" %}
```
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```
{% endcode %}

4\. Enable and start kubelet service using systemctl

{% code title="COMMAND" %}
```
sudo systemctl enable kubelet
```
{% endcode %}

5\. Create repo for Kubernetes container runtime, cri-o.&#x20;

{% hint style="info" %}
Note: replace the version with the current major version of Kunernetes.
{% endhint %}

{% code title="COMMAND" %}
```
export VERSION=1.24

sudo curl -4 -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo

sudo curl -4 -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${VERSION}/CentOS_7/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo

```
{% endcode %}

6\. install and enable cri-o, along with some other required packages for this course

{% code title="COMMAND" %}
```
sudo yum install -y cri-o tc vim wget git 
```
{% endcode %}

Change Driver to vfs for RHEL 7

{% code title="COMMAND" %}
```
sudo sed -i 's/driver = "overlay"/driver = "vfs"/g' /etc/containers/storage.conf
sudo sed -i 's/# storage_driver = "vfs"/storage_driver = "vfs"/g' /etc/crio/crio.conf
```
{% endcode %}

{% code title="COMMAND" %}
```
sudo systemctl enable --now crio
```
{% endcode %}

7\. Make sure that the `br_netfilter` the module is loaded. This can be done by running

{% code title="COMMAND" %}
```
lsmod | grep br_netfilter
```
{% endcode %}

Since `br_netfilter` is not in the loaded state, let's load this module manually:

{% code title="COMMAND" %}
```
sudo modprobe br_netfilter
echo br_netfilter | sudo tee /etc/modules-load.d/br_netfilter.conf
```
{% endcode %}

Now re-verify the module status:

{% code title="COMMAND" %}
```
    lsmod | grep br_netfilter
```
{% endcode %}

\
8\. As a requirement for your Linux Node's iptables to correctly see bridged traffic, you should ensure `net.bridge.bridge-nf-call-iptables` is set to 1 in your `sysctl` config. And, IP Forwarding is enabled.

{% code title="COMMAND" %}
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```
{% endcode %}

{% code title="COMMAND" %}
```
sudo sysctl --system
```
{% endcode %}

9\. If you do not have a DNS server to resolve the hostname then you must update your /etc/hosts file with the hostname and IP information of all the cluster nodes on all the nodes

{% code title="COMMAND" %}
```
echo $(hostname -I) $(hostname) | sudo tee -a /etc/hosts
```
{% endcode %}

10\. Finally we are ready to initialize our first node which will be kubernetes control-plane

{% code title="COMMAND" %}
```
sudo kubeadm config images pull -v=1
```
{% endcode %}

{% code title="COMMAND" %}
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16,2001:db8:42:0::/56 --cri-socket=unix:///run/crio/crio.sock --service-cidr=10.96.0.0/16,2001:db8:42:1::/112
```
{% endcode %}



{% code title="OUTPUT" %}
```
[init] Using Kubernetes version: v1.24.1
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [ip-10-0-2-77.ap-southeast-2.compute.internal kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.2.77]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [ip-10-0-2-77.ap-southeast-2.compute.internal localhost] and IPs [10.0.2.77 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [ip-10-0-2-77.ap-southeast-2.compute.internal localhost] and IPs [10.0.2.77 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 11.003788 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node ip-10-0-2-77.ap-southeast-2.compute.internal as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node ip-10-0-2-77.ap-southeast-2.compute.internal as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: 104xne.q4cpqmh2r40auj1n
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.2.77:6443 --token 104xne.q4cpqmh2r40auj1n \
	--discovery-token-ca-cert-hash sha256:928d29eaa4f7cc98b476a925f16e39cdeab8cfc151ed24168a8100c3a16df502 
[centos@ip-10-0-2-77 ~]$ 
```
{% endcode %}

11\. To start using your cluster, you need to run the following as a regular user:

{% code title="COMMAND" %}
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
{% endcode %}

12\. We will remove the default taints from the control-plane, so that we can use as a node where we can host pods.

{% code title="COMMAND" %}
```
kubectl describe node |grep -A1 Taints
```
{% endcode %}

{% code title="COMMAND" %}
```
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

kubectl describe node |grep -A1 Taints
```
{% endcode %}

13\. It's all good 👍&#x20;

{% code title="COMMAND" %}
```
kubectl get nodes

kubectl get pods --all-namespaces
```
{% endcode %}



{% code title="OUTPUT" %}
```
NAME                                           STATUS   ROLES           AGE   VERSION
ip-10-0-2-94.ap-southeast-2.compute.internal   Ready    control-plane   30m   v1.24.2


NAMESPACE     NAME                                                                   READY   STATUS    RESTARTS   AGE
kube-system   coredns-6d4b75cb6d-64cbt                                               1/1     Running   0          30m
kube-system   coredns-6d4b75cb6d-kv22t                                               1/1     Running   0          30m
kube-system   etcd-ip-10-0-2-94.ap-southeast-2.compute.internal                      1/1     Running   0          30m
kube-system   kube-apiserver-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          30m
kube-system   kube-controller-manager-ip-10-0-2-94.ap-southeast-2.compute.internal   1/1     Running   0          30m
kube-system   kube-proxy-tlftd                                                       1/1     Running   0          30m
kube-system   kube-scheduler-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          30m
```
{% endcode %}

14\. Deploy a pod network to the cluster

{% code title="COMMAND" %}
```
curl https://projectcalico.docs.tigera.io/manifests/calico.yaml -O
```
{% endcode %}

Clone the git repo, which includes the files required for further lab exercises.

{% code title="COMMAND" %}
```
git clone https://github.com/swapnil-linux/kubernetes-101
```
{% endcode %}

We will enable IPv6 in calico,

{% code title="COMMAND" %}
```
diff ~/calico.yaml ~/kubernetes-101/labs/install/calico.yaml
```
{% endcode %}

{% code title="COMMAND" %}
```
kubectl create -f ~/kubernetes-101/labs/install/calico.yaml
```
{% endcode %}



### Enable Shell auto-completion

Now, this is not a mandatory step but it is useful to get the list of supported options with kubectl just by pressing the TAB key on the keyboard. kubectl provides autocompletion support for Bash and Zsh, which can save you a lot of typing. To enable auto-completion we must first install bash-completion on the respective node. Since we would be using our master node most of the time, so we will install this package only on the controller node:

{% code title="COMMAND" %}
```
sudo yum -y install bash-completion
```
{% endcode %}

Next execute kubectl completion bash to get the script which would perform the auto completion for kubectl, this would give a long output on the console

{% code title="COMMAND" %}
```
kubectl completion bash
```
{% endcode %}

We will save the output from this command to our \~/.bashrc

{% code title="COMMAND" %}
```
kubectl completion bash >> ~/.bashrc
```
{% endcode %}

**OR,** If you want this to be available for all other users then you can create a new file inside /etc/bash\_completion.d/ and save the content:

{% code title="COMMAND" %}
```
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl
```
{% endcode %}

Next reload your shell and now you can enter `kubectl` and just press TAB which should give you a list of supported options:

{% code title="OUTPUT" %}
```
[root@controller ~]# kubectl <press TAB on the keyboard>
alpha          attach         completion     create         edit           kustomize      plugin         run            uncordon
annotate       auth           config         delete         exec           label          port-forward   scale          version
api-resources  autoscale      convert        describe       explain        logs           proxy          set            wait
api-versions   certificate    cordon         diff           expose         options        replace        taint
apply          cluster-info   cp             drain          get            patch          rollout        top
```
{% endcode %}

