# Service Discovery

Kubernetes runs cloud-native microservices apps that scale up and down, self-heal from failures, and regularly get replaced by newer releases. All of this makes individual application Pods unreliable. To solve this, Kubernetes has a super-stable Service object that fronts unreliable application Pods with a stable IP, DNS name, and port. All good so far, but in a big bustling environment like many Kubernetes clusters, apps need a way to find the other apps they work with. This is where service discovery comes into play.

There are two major components to service discovery:

* Registration&#x20;
* Discovery

## Service registration

Service registration is the process of an application listing its connection details in a service registry so other apps can find it and consume it.

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 11.05.13 am.png>)

A few important things to note about service discovery in Kubernetes:

1\. Kubernetes uses its internal DNS as a service registry\
2\. All Kubernetes Services are automatically registered with DNS

For this to work, Kubernetes provides a well-known internal DNS service that we usually call the “cluster DNS”. It’s well known because every Pod in the cluster is automatically configured to know where to find it. It’s implemented in the kube-system Namespace as a set of Pods managed by a Deployment called coredns and fronted by a Service called `kube-dns`. Behind the scenes, it’s based on a DNS technology called `CoreDNS` and runs as a Kubernetes-native application.

This command lists the Pods running the cluster DNS.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-6d4b75cb6d-gbc9x   1/1     Running   0          38h
coredns-6d4b75cb6d-j2dr7   1/1     Running   0          38h
[centos@ip-10-0-2-94 ~]$ 
```

This lists the Deployment managing them.

```
[centos@ip-10-0-2-94 ~]$ kubectl get deploy -n kube-system -l k8s-app=kube-dns
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   2/2     2            2           38h
[centos@ip-10-0-2-94 ~]$ 
```

This lists the Service fronting them. The ClusterIP is the well known IP configured on every Pod/container.

```
[centos@ip-10-0-2-94 ~]$ kubectl get svc -n kube-system -l k8s-app=kube-dns
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   38h
[centos@ip-10-0-2-94 ~]$ 
```



The process of service registration looks like this (exact flow might slightly differ):

1. You post a new Service manifest to the API server
2. The request is authenticated, authorized, and subjected to admission policies
3. The Service is allocated a stable virtual IP address called a ClusterIP
4. An Endpoints object (or EndpointSlice) is created to hold a list of healthy Pods matching the Service’s label selector
5. The Pod network is configured to handle traffic sent to the ClusterIP (more on this later)
6. The Service’s name and IP are registered with the cluster DNS

We mentioned earlier that cluster DNS is a Kubernetes-native application. This means it knows it’s running on Kubernetes and implements a controller that watches the API server for new Service objects. Any time it observes one, it automatically creates the DNS records mapping the Service name to its ClusterIP. This means apps, and even Services, don’t need to perform their own service registration – the cluster DNS does it for them.

It’s important to understand that the name registered in DNS for the Service is the value stored in its `metadata.name` property. This is why _it’s important that Service names are valid DNS names and don’t include exotic characters_. The ClusterIP is dynamically assigned by Kubernetes.

The below figure shows the `ent` Service that will load-balance traffic to two `Pods`. It also shows the `Endpoints` object with the IPs of the two Pods matching the Service’s label selector.

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 11.12.44 am.png>)

The kube-proxy agent on every node is also watching the API server for new Endpoints/EndpointSlice objects. When it sees one, it creates local networking rules on all worker nodes to redirect ClusterIP traffic to Pod IPs. In modern Linux-based Kubernetes clusters, the technology used to create these rules is the Linux IP Virtual Server (IPVS). Older versions used iptables.

At this point the Service is fully registered and ready to be used:

• Its front-end configuration is registered with DNS\
• Its back-end label selector is created\
• Its Endpoints object (or EndpointSlice) is created\
• kube-proxies have created the necessary local routing rules on worker nodes

Let’s summarise the service registration process with the help of a simple flow diagram.

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 11.21.43 am.png>)

## Service discovery

For service discovery to work, apps need to know both of the following.&#x20;

1. The name of the Service fronting the apps they want to connect to
2. How to convert the name to an IP address

Application developers are responsible for point 1. They need to code apps with the names of other apps they want to consume. Actually, they need to code the names of Services fronting the remote apps.

Kubernetes automatically configures every container so it can find and use the cluster DNS to convert Service names to IPs. It does this by populating every container’s `/etc/resolv.conf` file with the IP address of the cluster DNS Service as well as any search domains that should be appended to unqualified names.

The following snippet shows a container that is configured to send DNS queries to the cluster DNS at `10.96.0.10`. It also lists three search domains to append to unqualified names.

* myapp.svc.cluster.local
* svc.cluster.local
* cluster.local ap-southeast-2.compute.internal

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -it scaling-dbbc8fcdd-4pvxz -- bash
bash-5.1# cat /etc/resolv.conf 
search myapp.svc.cluster.local svc.cluster.local cluster.local ap-southeast-2.compute.internal
nameserver 10.96.0.10
options ndots:5
bash-5.1# 
```

### Some network magic

ClusterIPs are on a “special” network called the service network, and there are no routes to it! This means containers send all ClusterIP traffic to their default gateway.

* The container’s default gateway sends the traffic to the node it’s running on.
* The node doesn’t have a route to the service network either, so it sends it to its own default gateway. Doing this causes the traffic to be processed by the node’s kernel, which is where the magic happens...
* Every time a node’s kernel processes traffic headed for an address on the service network, a trap occurs and the traffic is redirected to the IP of a healthy Pod matching the Service’s label selector. `kube-proxy` watches the K8S API for new Services and Endpoints objects, when it sees them, it creates local IPVS rules telling the node to intercept traffic destined for the Service’s ClusterIP and forward it to individual Pod IPs.

{% hint style="info" %}
_Kubernetes originally used iptables to do this trapping and load-balancing. However, it was replaced by IPVS in Kubernetes 1.11. The is because IPVS is a high-performance kernel-based L4 load-balancer that scales better than iptables and implements better load-balancing._
{% endhint %}

Let’s quickly summarise the service discovery process with the help of the flow diagram

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 11.35.27 am.png>)

### Service discovery and Namespaces

It’s important to understand that every cluster has an address space, and we can use Namespaces to partition this address space.

Cluster address spaces are based on a DNS domain that we call the cluster domain. The domain name is usually `cluster.local` and objects have unique names within it. For example, a Service called `ent` will have a fully qualified domain name (FQDN) of `ent.default.svc.cluster.local`

The format is `<object-name>.<namespace>.svc.cluster.local`

Namespaces let you partition the address space below the cluster domain. For example, creating a couple of Namespaces called `dev` and `prod` will partition the cluster address space into the following two address spaces.

• **dev**: `<service-name>.dev.svc.cluster.local`\
• **prod**: `<service-name>.prod.svc.cluster.local`

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 11.39.02 am.png>)

Objects can connect to Services in the local Namespace using short names such as `ent` and `cer`. But connecting to objects in a remote Namespace requires FQDNs such as `ent.dev.svc.cluster.local` and `cer.dev.svc.cluster.local`.

{% hint style="info" %}
You can change the cluster base DNS by editing the kubelet config file on ALL Nodes, located at `/var/lib/kubelet/config.yaml` or set the clusterDomain during `kubeadm init`

`kubeadm init --help |grep domain`

&#x20;     `--service-dns-domain string            Use alternative domain for services, e.g. "myorg.internal". (default "cluster.local")`
{% endhint %}

