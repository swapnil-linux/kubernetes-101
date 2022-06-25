# 6. Kubernetes Service

In previous chapters, you’ve deployed applications to Kubernetes and seen how controllers add self-healing, scaling and rollouts. Despite all of this, Pods are still unreliable and you should never connect directly to them. This is where Services come to the rescue by providing stable and reliable networking for a set of unreliable Pods.

When Pods fail, they get replaced by new ones with new IPs. Scaling-up introduces new Pods with new IP addresses. Scaling down removes Pods. Rolling updates delete existing Pods and replace them with new ones with new IPs. All of this creates massive IP churn and demonstrates why you should never connect directly to any Pod.

#### You also need to know 3 fundamental things about Kubernetes Services.

1\) Service object in Kubernetes provides stable networking for Pods. Just like a Pod, ReplicaSet, or Deployment, a Kubernetes Service is a REST object in the API that you define in a manifest file and post to the API server.

2\) Every Service gets its own stable IP address, its own stable DNS name, and its own stable port.

3\) Services use labels and selectors to dynamically select the Pods they send traffic to.

## Service Theory

The below figure shows a simple application managed by a Deployment controller. There’s a client (which could be another Pod) that needs a reliable network endpoint to access the Pods. Remember, it’s a bad idea to talk directly to individual Pods because scaling operations, rollouts, rollbacks, and even failures can make them disappear.

![](<../.gitbook/assets/Screen Shot 2022-06-25 at 4.11.14 pm.png>)

The below figure shows the same application with a Service thrown into the mix. The Service fronts the Pods with a stable IP, DNS name, and port. It also load-balances traffic to Pods with the right labels.

![](<../.gitbook/assets/Screen Shot 2022-06-25 at 4.12.09 pm.png>)

With a Service in place, the Pods can scale up and down, they can fail, and they can be updated and rolled back. Despite all of this, clients will continue to access them without interruption. This is because the Service is observing the changes and updating its list of healthy Pods it sends traffic to. But it never changes its stable IP, DNS, and port.

### Labels and loose coupling

Services are loosely coupled with Pods via labels and selectors. This is the same technology that loosely couples Deployments to Pods and is key to the flexibility of Kubernetes. Below Figure shows an example where 3 Pods are labelled as `zone=prod` and `ver=v1`, and the Service has a selector that matches.

![](<../.gitbook/assets/Screen Shot 2022-06-25 at 4.14.34 pm.png>)

#### For a Service to send traffic to a Pod, the Pod needs every label the Service is selecting on.&#x20;

![](<../.gitbook/assets/Screen Shot 2022-06-25 at 4.16.36 pm.png>)

#### It can also have additional labels the Service isn’t looking for.

![](<../.gitbook/assets/Screen Shot 2022-06-25 at 4.17.15 pm.png>)

The following excerpts, from a Service YAML and Deployment YAML, show how selectors and labels work.

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/ns/shield-app.yml 
apiVersion: v1
kind: Service
metadata:
  namespace: shield
  name: the-bus
spec:
  type: NodePort
  ports:
  - nodePort: 31112
    port: 8080
    targetPort: 8080
  selector:
    env: marvel       <<======= Send to Pods with these labels
---
apiVersion: v1
kind: Pod
metadata:
  namespace: shield
  name: triskelion
  labels:
    env: marvel   <<======= Pod Labels
spec:
  containers:
  - image: quay.io/mask365/scaling:latest
    name: bus-ctr
    ports:
    - containerPort: 8080
    imagePullPolicy: Always
[centos@ip-10-0-2-94 ~]$ 
```

## Accessing Services from inside the cluster

Kubernetes supports several types of Service. The default type is ClusterIP.

A ClusterIP Service has a stable virtual IP address that is only accessible from inside the cluster. It’s programmed into the internal network fabric and guaranteed to be stable for the life of the Service. Programmed into the network fabric is a fancy way of saying the network just knows about it and you don’t need to bother with the details.

Anyway, every Service you create gets a ClusterIP that’s registered, along with the name of the Service, in the cluster’s internal DNS service. All Pods in the cluster are pre-programmed to use the cluster’s DNS service, meaning all Pods can convert Service names to ClusterIPs.

Let’s look at a simple example.

Creating a new Service called “skippy” will dynamically assign a stable ClusterIP. This name and ClusterIP are automatically registered with the cluster’s DNS service. These are all guaranteed to be long-lived and stable. As all Pods in the cluster send service discovery requests to the internal DNS, they can all resolve “skippy” to the ClusterIP. iptables or IPVS rules are distributed across the nodes to ensure traffic sent to the ClusterIP gets routed to Pods with the label the Service is selecting on.

```
[centos@ip-10-0-2-94 ~]$ sudo iptables -t nat -L -n -v|grep shield
    0     0 KUBE-MARK-MASQ  all  --  *      *       10.85.0.55           0.0.0.0/0            /* shield/the-bus */
    0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* shield/the-bus */ tcp to:10.85.0.55:8080
    0     0 KUBE-SVC-JFJEH6DLPMFCJKSC  tcp  --  *      *       0.0.0.0/0            10.96.69.229         /* shield/the-bus cluster IP */ tcp dpt:8080
    0     0 KUBE-SEP-4CPU4NSVXIWEI6UY  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* shield/the-bus -> 10.85.0.55:8080 */
[centos@ip-10-0-2-94 ~]$
```

Net result... if a Pod knows the name of a Service, it can resolve it to a ClusterIP address and connect to the Pods behind it.

This only works for Pods and other objects on the cluster, as it requires access to the cluster’s DNS service. It does not work outside of the cluster.

## Accessing Services from outside the cluster

Kubernetes has two types of Service for requests originating from outside the cluster.

• NodePort\
• LoadBalancer

**NodePort Services** build on top of the ClusterIP type and allow external clients to hit a dedicated port on every cluster node and reach the Service. We call this dedicated port the “NodePort”.

You already know the default Service type is ClusterIP and it registers a DNS name, virtual IP, and port with the cluster’s DNS. NodePort Services build on this by adding an additional NodePort that can be used to reach the Service from outside the cluster.

The following YAML shows a NodePort Service called “skippy”.

```
apiVersion: v1
kind: Service
metadata:
  name: skippy
spec:
  type: NodePort   <<===== type of service
  ports:
  - port: 8080
    nodePort: 30050  <<===== port on which it will be accessible 
  selector:
app: hello-world
```

Pods on the cluster can access this Service by its name (skippy) on port 8080. Clients connecting from outside the cluster can send traffic to any cluster node on port 30050.

![](<../.gitbook/assets/Screen Shot 2022-06-26 at 7.09.56 am.png>)

**LoadBalancer Services** make external access even easier by integrating with an internet-facing load-balancer on your underlying cloud platform. You get a high-performance highly-available public IP or DNS name that you can access the Service from. You can even register friendly DNS names to make access even simpler – you don’t need to know cluster node names or IPs.

They’re extremely easy to use, but they only work on clouds that support them.

## Service discovery

There is an entire chapter dedicated to a service discovery deep dive, so this section will be brief.

Kubernetes implements Service discovery in a couple of ways:

• DNS (preferred)\
• Environment variables (definitely not preferred)

Kubernetes clusters run an internal DNS service that is the centre of service discovery. Service names are automatically registered with the cluster DNS, and every Pod and container is pre-configured to use the cluster DNS for discovery. This means every Pod/container can resolve every Service name to a ClusterIP and connect to the Pods behind it.

The alternative form of service discovery is through environment variables. In this setup, every Pod gets a set of environment variables that resolve Services currently on the cluster. However, they cannot learn about new Services added after the Pod was created. This is a major reason DNS is the preferred method.
