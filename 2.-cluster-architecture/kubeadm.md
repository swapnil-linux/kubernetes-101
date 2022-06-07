# kubeadm

## Creating a cluster with kubeadm

Using `kubeadm`, you can create a minimum viable Kubernetes cluster that conforms to best practices. In fact, you can use `kubeadm` to set up a cluster that will pass the [Kubernetes Conformance tests](https://kubernetes.io/blog/2017/10/software-conformance-certification). `kubeadm` also supports other cluster lifecycle functions, such as [bootstrap tokens](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/) and cluster upgrades.

The `kubeadm` tool is good if you need:

* A simple way for you to try out Kubernetes, possibly for the first time.
* A way for existing users to automate setting up a cluster and test their application.
* A building block in other echosystem and/or installer tools with a larger scope.

You can install and use `kubeadm` on various machines: your laptop, a set of cloud servers, a Raspberry Pi, and more. Whether you're deploying into the cloud or on-premises, you can integrate `kubeadm` into provisioning systems such as Ansible or Terraform.

### &#x20;Prerequisites&#x20;

* One or more machines running a deb/rpm-compatible Linux OS; for example: Ubuntu or CentOS.
* 2 GiB or more of RAM per machine--any less leaves little room for your apps.
* At least 2 CPUs on the machine that you use as a control-plane node.
* Full network connectivity among all machines in the cluster. You can use either a public or a private network.

You also need to use a version of `kubeadm` that can deploy the version of Kubernetes that you want to use in your new cluster.

### Steps to create Kubernetes Cluster

#### Initializing your control-plane node <a href="#initializing-your-control-plane-node" id="initializing-your-control-plane-node"></a>

The control-plane node is the machine where the control plane components run, including [etcd](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/) (the cluster database) and the [API Server](https://kubernetes.io/docs/concepts/overview/components/#kube-apiserver) (which the [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) command line tool communicates with).

1. (Recommended) If you have plans to upgrade this single control-plane `kubeadm` cluster to high availability you should specify the `--control-plane-endpoint` to set the shared endpoint for all control-plane nodes. Such an endpoint can be either a DNS name or an IP address of a load-balancer.
2. Choose a Pod network add-on, and verify whether it requires any arguments to be passed to `kubeadm init`. Depending on which third-party provider you choose, you might need to set the `--pod-network-cidr` to a provider-specific value. See [Installing a Pod network add-on](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network).
3. (Optional) `kubeadm` tries to detect the container runtime by using a list of well known endpoints. To use different container runtime or if there are more than one installed on the provisioned node, specify the `--cri-socket` argument to `kubeadm`. See [Installing a runtime](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime).
4. (Optional) Unless otherwise specified, `kubeadm` uses the network interface associated with the default gateway to set the advertise address for this particular control-plane node's API server. To use a different network interface, specify the `--apiserver-advertise-address=<ip-address>` argument to `kubeadm init`. To deploy an IPv6 Kubernetes cluster using IPv6 addressing, you must specify an IPv6 address, for example `--apiserver-advertise-address=fd00::101`

To initialize the control-plane node run:

```bash
kubeadm init <args>
```

#### Considerations about apiserver-advertise-address and ControlPlaneEndpoint <a href="#considerations-about-apiserver-advertise-address-and-controlplaneendpoint" id="considerations-about-apiserver-advertise-address-and-controlplaneendpoint"></a>

While `--apiserver-advertise-address` can be used to set the advertise address for this particular control-plane node's API server, `--control-plane-endpoint` can be used to set the shared endpoint for all control-plane nodes.

`--control-plane-endpoint` allows both IP addresses and DNS names that can map to IP addresses. Please contact your network administrator to evaluate possible solutions with respect to such mapping.

Here is an example mapping:

```
192.168.0.102 cluster-endpoint
```

Where `192.168.0.102` is the IP address of this node and `cluster-endpoint` is a custom DNS name that maps to this IP. This will allow you to pass `--control-plane-endpoint=cluster-endpoint` to `kubeadm init` and pass the same DNS name to `kubeadm join`. Later you can modify `cluster-endpoint` to point to the address of your load-balancer in an high availability scenario.

Turning a single control plane cluster created without `--control-plane-endpoint` into a highly available cluster is not supported by kubeadm.

#### &#x20;Installing a Pod network add-on[ ](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)

\
Several external projects provide Kubernetes Pod networks using CNI, some of which also support [Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).

See a list of add-ons that implement the [Kubernetes networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model).

You can install a Pod network add-on with the following command on the control-plane node or a node that has the kubeconfig credentials:

```bash
kubectl apply -f <add-on.yaml>
```

You can install only one Pod network per cluster.

Once a Pod network has been installed, you can confirm that it is working by checking that the CoreDNS Pod is `Running` in the output of `kubectl get pods --all-namespaces`. And once the CoreDNS Pod is up and running, you can continue by joining your nodes.

If your network is not working or CoreDNS is not in the `Running` state, check out the [troubleshooting guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/) for `kubeadm`.

#### Managed node labels <a href="#managed-node-labels" id="managed-node-labels"></a>

By default, kubeadm enables the [NodeRestriction](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#noderestriction) admission controller that restricts what labels can be self-applied by kubelets on node registration. The admission controller documentation covers what labels are permitted to be used with the kubelet `--node-labels` option. The `node-role.kubernetes.io/control-plane` label is such a restricted label and kubeadm manually applies it using a privileged client after a node has been created. To do that manually you can do the same by using `kubectl label` and ensure it is using a privileged kubeconfig such as the kubeadm managed `/etc/kubernetes/admin.conf`.

#### &#x20;Control plane node isolation

By default, your cluster will not schedule Pods on the control plane nodes for security reasons. If you want to be able to schedule Pods on the control plane nodes, for example for a single machine Kubernetes cluster, run:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
```

The output will look something like:

```
node "test-01" untainted
...
```

This will remove the `node-role.kubernetes.io/control-plane` and `node-role.kubernetes.io/master` taints from any nodes that have them, including the control plane nodes, meaning that the scheduler will then be able to schedule Pods everywhere.



#### Joining your nodes <a href="#join-nodes" id="join-nodes"></a>

The nodes are where your workloads (containers and Pods, etc) run. To add new nodes to your cluster do the following for each machine:

* SSH to the machine
* Become root (e.g. `sudo su -`)
* [Install a runtime](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime) if needed
*   Run the command that was output by `kubeadm init`. For example:

    ```bash
    kubeadm join --token <token> <control-plane-host>:<control-plane-port> --discovery-token-ca-cert-hash sha256:<hash>
    ```

If you do not have the token, you can get it by running the following command on the control-plane node:

```bash
kubeadm token list
```

The output is similar to this:

```
TOKEN                    TTL  EXPIRES              USAGES           DESCRIPTION            EXTRA GROUPS
8ewj1p.9r9hcjoqgajrj4gi  23h  2018-06-12T02:51:28Z authentication,  The default bootstrap  system:
                                                   signing          token generated by     bootstrappers:
                                                                    'kubeadm init'.        kubeadm:
                                                                                           default-node-token
```

By default, tokens expire after 24 hours. If you are joining a node to the cluster after the current token has expired, you can create a new token by running the following command on the control-plane node:

```bash
kubeadm token create
```

The output is similar to this:

```
5didvk.d09sbcov8ph2amjw
```

If you don't have the value of `--discovery-token-ca-cert-hash`, you can get it by running the following command chain on the control-plane node:

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

The output is similar to:

```
8cb2de97839780a412b93877f8507ad6c94f73add17d5d7058e91741c9d5ec78
```

#### (Optional) Controlling your cluster from machines other than the control-plane node <a href="#optional-controlling-your-cluster-from-machines-other-than-the-control-plane-node" id="optional-controlling-your-cluster-from-machines-other-than-the-control-plane-node"></a>

In order to get a kubectl on some other computer (e.g. laptop) to talk to your cluster, you need to copy the administrator kubeconfig file from your control-plane node to your workstation like this:

```bash
scp root@<control-plane-host>:/etc/kubernetes/admin.conf .
kubectl --kubeconfig ./admin.conf get nodes
```

\
