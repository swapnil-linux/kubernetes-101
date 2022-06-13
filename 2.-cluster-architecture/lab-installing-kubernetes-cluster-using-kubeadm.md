# Lab: Installing kubernetes cluster using kubeadm

1. Configure kubernetes repo

```
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

2\. Set SELinux in permissive mode (effectively disabling it)

```
sudo setenforce 0
```

```
// Some codesudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

3\. Instal...

```
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```

```
[centos@ip-10-0-2-77 ~]$ sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: download.cf.centos.org
 * extras: download.cf.centos.org
 * updates: download.cf.centos.org
Resolving Dependencies
--> Running transaction check
---> Package kubeadm.x86_64 0:1.24.1-0 will be installed
--> Processing Dependency: kubernetes-cni >= 0.8.6 for package: kubeadm-1.24.1-0.x86_64
--> Processing Dependency: cri-tools >= 1.19.0 for package: kubeadm-1.24.1-0.x86_64
---> Package kubectl.x86_64 0:1.24.1-0 will be installed
---> Package kubelet.x86_64 0:1.24.1-0 will be installed
--> Processing Dependency: socat for package: kubelet-1.24.1-0.x86_64
--> Processing Dependency: ebtables for package: kubelet-1.24.1-0.x86_64
--> Processing Dependency: conntrack for package: kubelet-1.24.1-0.x86_64
--> Running transaction check
---> Package conntrack-tools.x86_64 0:1.4.4-7.el7 will be installed
--> Processing Dependency: libnetfilter_cttimeout.so.1(LIBNETFILTER_CTTIMEOUT_1.1)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cttimeout.so.1(LIBNETFILTER_CTTIMEOUT_1.0)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cthelper.so.0(LIBNETFILTER_CTHELPER_1.0)(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_queue.so.1()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cttimeout.so.1()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
--> Processing Dependency: libnetfilter_cthelper.so.0()(64bit) for package: conntrack-tools-1.4.4-7.el7.x86_64
---> Package cri-tools.x86_64 0:1.24.0-0 will be installed
---> Package ebtables.x86_64 0:2.0.10-16.el7 will be installed
---> Package kubernetes-cni.x86_64 0:0.8.7-0 will be installed
---> Package socat.x86_64 0:1.7.3.2-2.el7 will be installed
--> Running transaction check
---> Package libnetfilter_cthelper.x86_64 0:1.0.0-11.el7 will be installed
---> Package libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7 will be installed
---> Package libnetfilter_queue.x86_64 0:1.0.2-2.el7_2 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===============================================================================================================
 Package                            Arch               Version                    Repository              Size
===============================================================================================================
Installing:
 kubeadm                            x86_64             1.24.1-0                   kubernetes             9.5 M
 kubectl                            x86_64             1.24.1-0                   kubernetes             9.9 M
 kubelet                            x86_64             1.24.1-0                   kubernetes              20 M
Installing for dependencies:
 conntrack-tools                    x86_64             1.4.4-7.el7                base                   187 k
 cri-tools                          x86_64             1.24.0-0                   kubernetes             5.9 M
 ebtables                           x86_64             2.0.10-16.el7              base                   123 k
 kubernetes-cni                     x86_64             0.8.7-0                    kubernetes              19 M
 libnetfilter_cthelper              x86_64             1.0.0-11.el7               base                    18 k
 libnetfilter_cttimeout             x86_64             1.0.0-7.el7                base                    18 k
 libnetfilter_queue                 x86_64             1.0.2-2.el7_2              base                    23 k
 socat                              x86_64             1.7.3.2-2.el7              base                   290 k

Transaction Summary
===============================================================================================================
Install  3 Packages (+8 Dependent packages)

Total download size: 65 M
Installed size: 279 M
Downloading packages:
warning: /var/cache/yum/x86_64/7/base/packages/ebtables-2.0.10-16.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Public key for ebtables-2.0.10-16.el7.x86_64.rpm is not installed
(1/11): ebtables-2.0.10-16.el7.x86_64.rpm                                               | 123 kB  00:00:00     
(2/11): conntrack-tools-1.4.4-7.el7.x86_64.rpm                                          | 187 kB  00:00:00     
warning: /var/cache/yum/x86_64/7/kubernetes/packages/9165e89a2de0f1a2acfb151177ac6985022ee0c2a8a78d45a4982aa1b11ffd68-cri-tools-1.24.0-0.x86_64.rpm: Header V4 RSA/SHA512 Signature, key ID 3e1ba8d5: NOKEY
Public key for 9165e89a2de0f1a2acfb151177ac6985022ee0c2a8a78d45a4982aa1b11ffd68-cri-tools-1.24.0-0.x86_64.rpm is not installed
(3/11): 9165e89a2de0f1a2acfb151177ac6985022ee0c2a8a78d45a4982aa1b11ffd68-cri-tools-1.24 | 5.9 MB  00:00:01     
(4/11): 7f171021fcae441d9128b4c298a8082281e93864f5c137f097b89ec4749d7b7b-kubeadm-1.24.1 | 9.5 MB  00:00:01     
(5/11): 17013403794d47f80ade3299c74c3a646d37f195c1057da4db74fd3fd78270f1-kubectl-1.24.1 | 9.9 MB  00:00:02     
(6/11): libnetfilter_cthelper-1.0.0-11.el7.x86_64.rpm                                   |  18 kB  00:00:00     
(7/11): libnetfilter_queue-1.0.2-2.el7_2.x86_64.rpm                                     |  23 kB  00:00:00     
(8/11): socat-1.7.3.2-2.el7.x86_64.rpm                                                  | 290 kB  00:00:00     
(9/11): libnetfilter_cttimeout-1.0.0-7.el7.x86_64.rpm                                   |  18 kB  00:00:00     
(10/11): d184b7647df76898e431cfc9237dea3f8830e3e3398d17b0bf90c1b479984b3f-kubelet-1.24. |  20 MB  00:00:03     
(11/11): db7cb5cb0b3f6875f54d10f02e625573988e3e91fd4fc5eef0b1876bb18604ad-kubernetes-cn |  19 MB  00:00:02     
---------------------------------------------------------------------------------------------------------------
Total                                                                           10 MB/s |  65 MB  00:00:06     
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-9.2009.0.el7.centos.x86_64 (installed)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Retrieving key from https://packages.cloud.google.com/yum/doc/yum-key.gpg
Importing GPG key 0x13EDEF05:
 Userid     : "Rapture Automatic Signing Key (cloud-rapture-signing-key-2022-03-07-08_01_01.pub)"
 Fingerprint: a362 b822 f6de dc65 2817 ea46 b53d c80d 13ed ef05
 From       : https://packages.cloud.google.com/yum/doc/yum-key.gpg
Importing GPG key 0x307EA071:
 Userid     : "Rapture Automatic Signing Key (cloud-rapture-signing-key-2021-03-01-08_01_09.pub)"
 Fingerprint: 7f92 e05b 3109 3bef 5a3c 2d38 feea 9169 307e a071
 From       : https://packages.cloud.google.com/yum/doc/yum-key.gpg
Importing GPG key 0x836F4BEB:
 Userid     : "gLinux Rapture Automatic Signing Key (//depot/google3/production/borg/cloud-rapture/keys/cloud-rapture-pubkeys/cloud-rapture-signing-key-2020-12-03-16_08_05.pub) <glinux-team@google.com>"
 Fingerprint: 59fe 0256 8272 69dc 8157 8f92 8b57 c5c2 836f 4beb
 From       : https://packages.cloud.google.com/yum/doc/yum-key.gpg
Retrieving key from https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
Importing GPG key 0x3E1BA8D5:
 Userid     : "Google Cloud Packages RPM Signing Key <gc-team@google.com>"
 Fingerprint: 3749 e1ba 95a8 6ce0 5454 6ed2 f09c 394c 3e1b a8d5
 From       : https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : ebtables-2.0.10-16.el7.x86_64                                                              1/11 
  Installing : libnetfilter_cthelper-1.0.0-11.el7.x86_64                                                  2/11 
  Installing : kubectl-1.24.1-0.x86_64                                                                    3/11 
  Installing : libnetfilter_cttimeout-1.0.0-7.el7.x86_64                                                  4/11 
  Installing : libnetfilter_queue-1.0.2-2.el7_2.x86_64                                                    5/11 
  Installing : conntrack-tools-1.4.4-7.el7.x86_64                                                         6/11 
  Installing : cri-tools-1.24.0-0.x86_64                                                                  7/11 
  Installing : socat-1.7.3.2-2.el7.x86_64                                                                 8/11 
  Installing : kubernetes-cni-0.8.7-0.x86_64                                                              9/11 
  Installing : kubelet-1.24.1-0.x86_64                                                                   10/11 
  Installing : kubeadm-1.24.1-0.x86_64                                                                   11/11 
  Verifying  : socat-1.7.3.2-2.el7.x86_64                                                                 1/11 
  Verifying  : conntrack-tools-1.4.4-7.el7.x86_64                                                         2/11 
  Verifying  : kubernetes-cni-0.8.7-0.x86_64                                                              3/11 
  Verifying  : kubelet-1.24.1-0.x86_64                                                                    4/11 
  Verifying  : cri-tools-1.24.0-0.x86_64                                                                  5/11 
  Verifying  : libnetfilter_queue-1.0.2-2.el7_2.x86_64                                                    6/11 
  Verifying  : libnetfilter_cttimeout-1.0.0-7.el7.x86_64                                                  7/11 
  Verifying  : kubectl-1.24.1-0.x86_64                                                                    8/11 
  Verifying  : kubeadm-1.24.1-0.x86_64                                                                    9/11 
  Verifying  : libnetfilter_cthelper-1.0.0-11.el7.x86_64                                                 10/11 
  Verifying  : ebtables-2.0.10-16.el7.x86_64                                                             11/11 

Installed:
  kubeadm.x86_64 0:1.24.1-0           kubectl.x86_64 0:1.24.1-0           kubelet.x86_64 0:1.24.1-0          

Dependency Installed:
  conntrack-tools.x86_64 0:1.4.4-7.el7                   cri-tools.x86_64 0:1.24.0-0                           
  ebtables.x86_64 0:2.0.10-16.el7                        kubernetes-cni.x86_64 0:0.8.7-0                       
  libnetfilter_cthelper.x86_64 0:1.0.0-11.el7            libnetfilter_cttimeout.x86_64 0:1.0.0-7.el7           
  libnetfilter_queue.x86_64 0:1.0.2-2.el7_2              socat.x86_64 0:1.7.3.2-2.el7                          

Complete!
[centos@ip-10-0-2-77 ~]$ 
```

```
[centos@ip-10-0-2-77 ~]$ sudo systemctl enable --now kubelet
Created symlink from /etc/systemd/system/multi-user.target.wants/kubelet.service to /usr/lib/systemd/system/kubelet.service.
[centos@ip-10-0-2-77 ~]$ 
```

```
export VERSION=1.24

sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo

sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${VERSION}/CentOS_7/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo

```

```
[centos@ip-10-0-2-77 ~]$ sudo systemctl enable crio
Created symlink from /etc/systemd/system/cri-o.service to /usr/lib/systemd/system/crio.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/crio.service to /usr/lib/systemd/system/crio.service.
[centos@ip-10-0-2-77 ~]$ sudo systemctl start crio
[centos@ip-10-0-2-77 ~]$ 
```

Make sure that the `br_netfilter` module is loaded. This can be done by running

```
# lsmod | grep br_netfilter
```

Since `br_netfilter` is not in loaded state, I will load this module manually:

```
[root@controller ~]# modprobe br_netfilter
```

Now re-verify the module status:

```
[root@controller ~]# lsmod | grep br_netfilter
br_netfilter           24576  0
bridge                188416  1 br_netfilter
```

\
As a requirement for your Linux Node's iptables to correctly see bridged traffic, you should ensure `net.bridge.bridge-nf-call-iptables` is set to 1 in your `sysctl` config

\
And, IP Forwarding is enabled.

```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

```
sudo sysctl --system

```

If you do not have a [DNS server](https://www.golinuxcloud.com/configure-dns-server-bind-chroot-named-centos/) to resolve the hostname then you must update your /etc/hosts file with the hostname and IP information of all the cluster nodes on all the nodes

```
echo $(hostname -I) $(hostname) | sudo tee -a /etc/hosts
```

```
[centos@ip-10-0-2-77 ~]$ sudo kubeadm config images pull -v=1
I0613 06:28:10.812388    8598 initconfiguration.go:117] detected and using CRI socket: unix:///var/run/crio/crio.sock
I0613 06:28:10.813831    8598 kubelet.go:214] the value of KubeletConfiguration.cgroupDriver is empty; setting it to "systemd"
[config/images] Pulled k8s.gcr.io/kube-apiserver:v1.24.1
[config/images] Pulled k8s.gcr.io/kube-controller-manager:v1.24.1
[config/images] Pulled k8s.gcr.io/kube-scheduler:v1.24.1
[config/images] Pulled k8s.gcr.io/kube-proxy:v1.24.1
[config/images] Pulled k8s.gcr.io/pause:3.7
[config/images] Pulled k8s.gcr.io/etcd:3.5.3-0
[config/images] Pulled k8s.gcr.io/coredns/coredns:v1.8.6
[centos@ip-10-0-2-77 ~]$ 

```

```
[centos@ip-10-0-2-77 ~]$ sudo kubeadm init
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

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

```
[centos@ip-10-0-2-77 ~]$ kubectl describe node |grep -A1 Taints
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
                    node-role.kubernetes.io/master:NoSchedule
```

```
[centos@ip-10-0-2-77 ~]$ kubectl taint nodes --all node-role.kubernetes.io/master-
node/ip-10-0-2-77.ap-southeast-2.compute.internal untainted
[centos@ip-10-0-2-77 ~]$ kubectl taint nodes --all node-role.kubernetes.io/control-plane-
node/ip-10-0-2-77.ap-southeast-2.compute.internal untainted
[centos@ip-10-0-2-77 ~]$ kubectl describe node |grep -A1 Taints
Taints:             <none>
Unschedulable:      false
[centos@ip-10-0-2-77 ~]$ 
```

```
[centos@ip-10-0-2-77 ~]$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created
[centos@ip-10-0-2-77 ~]$ 
```

```
sudo yum -y install bash-completion
```

### Enable shell auto-completion (Optional)

Now this is not a mandatory step but it is useful to get the list of supported options with kubectl just by pressing the TAB key on the keyboard. kubectl provides autocompletion support for Bash and Zsh, which can save you a lot of typing. To enable auto-completion we must first install bash-completion on the respective node. Since we would be using our master node most of the time, so we will install this package only on controller node:

```
[root@controller ~]# dnf -y install bash-completion
```

Next execute kubectl completion bash to get the script which would perform the auto completion for kubectl, this would give a long output on the console

```
[root@controller ~]# kubectl completion bash
```

We will save the output from this command to our \~/.bashrc for root user.

```
[root@controller ~]# kubectl completion bash >> ~/.bashrc
```

If you want this to be available for all other users then you can create a new file inside /etc/bash\_completion.d/ and save the content:

```
[root@controller ~]# kubectl completion bash >> /etc/bash_completion.d/kubectl
```

Next reload your shell and now you can enter `kubectl` and just press TAB which should give you a list of supported options:

```
[root@controller ~]# kubectl <press TAB on the keyboard>
alpha          attach         completion     create         edit           kustomize      plugin         run            uncordon
annotate       auth           config         delete         exec           label          port-forward   scale          version
api-resources  autoscale      convert        describe       explain        logs           proxy          set            wait
api-versions   certificate    cordon         diff           expose         options        replace        taint
apply          cluster-info   cp             drain          get            patch          rollout        top
```

&#x20;
