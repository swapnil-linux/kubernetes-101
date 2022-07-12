# Kubernetes Components

A Kubernetes cluster is made of control plane nodes and worker nodes. These are Linux hosts that can be virtual machines (VM), bare metal servers in your datacenters, or instances in a private or public cloud.

![](<../.gitbook/assets/1 (1).png>)

## The control plane

A Kubernetes control plane node runs a collection of system services that make up the control plane of the cluster. Sometimes we call them Masters, Heads or Head nodes. However, the term “master” is considered legacy and no longer used.

The simplest setups run a single control plane node. However, this is only suitable for labs and test environments. For production environments, multiple control plane nodes configured for high availability (HA) is vital. Generally speaking, 3 or 5 is recommended, and you should spread them across availability zones.

It’s also considered a good practice not to run user applications on control plane nodes. This frees them up to concentrate entirely on managing the cluster.

Let’s take a quick look at the different services making up the control plane. All of these services run on every control plane node.

### The API server

The API server is the Grand Central station of Kubernetes. All communication, be- tween all components, must go through the API server. We’ll get into the detail later, but it’s important to understand that internal system components, as well as external user components, all communicate through the API server – all roads lead to the API Server.

It exposes a RESTful API that you POST YAML configuration files to over HTTPS. These YAML files, which we sometimes call manifests, describe the desired state of an application. This desired state includes things like which container image to use, which ports to expose, and how many Pod replicas to run.

All requests to the API server are subject to authentication and authorization checks. Once these are done, the config in the YAML file is validated, persisted to the cluster store, and work is scheduled to the worker nodes.

### The cluster store

The cluster store is the only stateful part of the control plane and persistently stores the entire configuration and state of the cluster. As such, it’s a vital component of every Kubernetes cluster – no cluster store, no cluster.

The cluster store is currently based on etcd, a popular distributed database. As it’s the single source of truth for a cluster, you should run between 3-5 etcd replicas for high- availability, and you should provide adequate ways to recover when things go wrong.\


A default installation of Kubernetes installs a replica of the cluster store on every control plane node and automatically configures HA.

On the topic of availability, etcd prefers consistency over availability. This means it doesn’t tolerate split-brains and will halt updates to the cluster in order to maintain consistency. However, if this happens, user applications should continue to work, you just won’t be able to update the cluster config.

As with all distributed databases, consistency of writes to the database is vital. For example, multiple writes to the same value originating from different places need to be handled. etcd uses the popular RAFT consensus algorithm to accomplish this.

### The controller manager and controllers

The controller manager implements all the background controllers that monitor cluster components and respond to events.

Architecturally, the controller manager is a controller of controllers, meaning it spawns all the core controllers and monitors them.

Some of the core controllers include the Deployment controller, the StatefulSet controller, and the ReplicaSet controller. Each one is responsible for a small subset of cluster intelligence and runs as a background watch-loop constantly watching the API Server for changes.

The goal of each controller is to ensure the observed state of the cluster matches the desired state (more on this shortly).

The logic implemented by each controller is as follows, and is at the heart of Kubernetes and declarative design patterns.

1\. Obtain desired state

2\. Observe current state&#x20;

3\. Determine differences&#x20;

4\. Reconcile differences

### The scheduler

At a high level, the scheduler watches the API server for new work tasks and assigns them to appropriate healthy worker nodes. Behind the scenes, it implements complex logic that filters out nodes incapable of running tasks, and then ranks the nodes that are capable. The ranking system is complex, but the node with the highest ranking score is selected to run the task.

When identifying nodes capable of running a task, the scheduler performs various predicate checks. These include; is the node tainted, are there any affinity or anti-affinity rules, is the required network port available on the node, does it have sufficient available resources etc. Any node incapable of running the task is ignored, and those remaining are ranked according to things such as does it already have the required image, how much free resource does it have, how many tasks is it currently running. Each is worth points, and the node with the most points is selected to run the task.

If the scheduler doesn’t find a suitable node, the task isn’t scheduled and gets marked as pending.

The scheduler is only responsible for picking the nodes to run tasks, it isn’t responsible for running them. A task is normally a Pod/container. You’ll learn about Pods and containers in later chapters.

![](<../.gitbook/assets/Screen Shot 2022-07-12 at 8.21.02 am.png>)

## Worker nodes

Worker nodes are where user applications run. At a high-level they do three things:

1\. Watch the API server for new work assignments\
2\. Execute work assignments\
3\. Report back to the control plane (via the API server)

\


![](<../.gitbook/assets/Screen Shot 2022-07-12 at 8.23.18 am.png>)

Let’s look at the three major components of a worker node.

### Kubelet

The kubelet is the main Kubernetes agent and runs on every worker node.

When you join a node to a cluster, the process installs the kubelet, which is then responsible for registering it with the cluster. This process registers the node’s CPU, memory, and storage into the wider cluster pool.

One of the main jobs of the kubelet is to watch the API server for new work tasks. Any time it sees one, it executes the task and maintains a reporting channel back to the control plane.

If a kubelet can’t run a task, it reports back to the control plane and lets the control plane decide what actions to take. For example, if a kubelet cannot execute a task, it is not responsible for finding another node to run it on. It simply reports back to the control plane and the control plane decides what to do.

### Container runtime

The kubelet needs a container runtime to perform container-related tasks – things like pulling images and starting and stopping containers.

In the early days, Kubernetes had native support for Docker. More recently, it’s moved to a plugin model called the Container Runtime Interface (CRI). At a high-level, the CRI masks the internal machinery of Kubernetes and exposes a clean documented interface for 3rd-party container runtimes to plug into.

The Docker container runtime is bloated and not ideal for Kubernetes. Because of this, CRI-O and containerd are replacing it as the most common container runtime on Kubernetes.

### Kube-proxy

The last piece of the worker node puzzle is the kube-proxy. This runs on every node and is responsible for local cluster networking. It ensures each node gets its own unique IP address, and it implements local iptables or IPVS rules to handle routing and load-balancing of traffic on the Pod network. More on all of this later in the book.

## Kubernetes DNS

As well as the various control plane and worker components, every Kubernetes cluster has an internal DNS service that is vital to service discovery.

The cluster’s DNS service has a static IP address that is hard-coded into every Pod on the cluster. This ensures every container and Pod can locate it and use it for discovery. Service registration is also automatic. This means apps don’t need to be coded with the intelligence to register with Kubernetes service discovery.

Cluster DNS is based on the open-source CoreDNS project (https://coredns.io/).

Now that you understand the fundamentals of control plane nodes and worker nodes, let’s switch gears and see how to package applications to run on Kubernetes.

## Packaging apps for Kubernetes

An application needs to tick a few boxes to run on a Kubernetes cluster. These include.

1\. Packaged as a container Image\
2\. Wrapped in a Pod\
3\. Deployed via a declarative manifest file

It goes like this...

You write an application microservice in a language of your choice. You then build it into a container image and store it in a registry. At this point it’s _containerized_.

Next, you define a Kubernetes Pod to run the containerized application. At the kind of high level we’re at, a Pod is just a wrapper that allows a container to run on a Kubernetes cluster. Once you’ve defined the Pod, you’re ready to deploy the app to Kubernetes.

While it’s possible to run static Pods like this, the preferred model is to deploy all Pods via higher-level controllers. The most common controller is the Deployment. It offers scalability, self-healing, and rolling updates for stateless apps. You define Deployments in YAML manifest files that specify things like how many replicas to deploy and how to perform updates.

![](<../.gitbook/assets/Screen Shot 2022-07-12 at 8.34.21 am.png>)

Once everything is defined in the Deployment YAML file, you can use the Kubernetes command-line tool to post it to the API server as the desired state of the application, and Kubernetes will implement it.

## Pods

In the "Virtualisation" world, the atomic unit of scheduling is the virtual machine (VM). In the Docker world, it’s the container. Well... in the Kubernetes world, it’s the Pod.

{% hint style="info" %}
Note: Pods are objects in the Kubernetes API, so we capitalize the first letter. This might annoy you if you’re passionate about language and proper use of capitalization. However, it adds clarity and the official Kubernetes docs are moving towards this standard.
{% endhint %}

### Pods and containers

The very first thing to understand is that the term Pod comes from a pod of whales – in the English language we call a group of whales a pod of whales. As the Docker logo is a whale, Kubernetes ran with the whale concept and that’s why we have “Pods”.

![](<../.gitbook/assets/image (7).png>)

The simplest model is to run a single container in every Pod. This is why we often use the terms “Pod” and “container” interchangeably. However, there are advanced use-cases that run multiple containers in a single Pod. Powerful examples of multi-container Pods include:

• Service meshes

• Web containers supported by a helper container pulling updated content&#x20;

• Containers with a tightly coupled log scraper

The point is that a Kubernetes Pod is a construct for running one or more containers.



![](<../.gitbook/assets/Screen Shot 2022-07-12 at 8.49.49 am.png>)

### Pod anatomy

At the highest level, a Pod is a ring-fenced environment to run containers. Pods themselves don’t actually run applications – applications always run in containers, the Pod is just a sandbox to run one or more containers. Keeping it high level, Pods ring-fence an area of the host OS, build a network stack, create a bunch of kernel namespaces, and run one or more containers.

If you’re running multiple containers in a Pod, they all share the same Pod environment. This includes the network stack, volumes, IPC namespace, shared memory, and more. As an example, this means all containers in the same Pod will share the same IP address (the Pod’s IP).

![](<../.gitbook/assets/Screen Shot 2022-07-12 at 8.51.27 am.png>)

If two containers in the same Pod need to talk to each other (container-to-container within the Pod) they can use the Pod’s localhost interface.

Multi-container Pods are ideal when you have requirements for tightly coupled containers that may need to share memory and storage. However, if you don’t need to tightly couple containers, you should put them in their own Pods and loosely couple them over the network. This keeps things clean by having each Pod dedicated to a single task. However, it creates a lot of potentially un-encrypted east-west network traffic. You should seriously consider using a service mesh to secure traffic between Pods and provide better network observability.

### Pods as the unit of scaling

Pods are also the minimum unit of scheduling in Kubernetes. If you need to scale an app, you add or remove Pods. You do not scale by adding more containers to existing Pods. Multi-container Pods are only for situations where two different, but complementary, containers need to share resources.

![](<../.gitbook/assets/Screen Shot 2022-07-12 at 8.52.50 am.png>)

## Deployments

Most of the time you’ll deploy Pods indirectly via higher-level controllers. Examples of higher-level controllers include Deployments, DaemonSets, and StatefulSets.

As an example, a Deployment is a higher-level Kubernetes object that wraps around a Pod and adds features such as self-healing, scaling, zero-downtime rollouts, and versioned rollbacks.

Behind the scenes, Deployments, DaemonSets and StatefulSets are implemented as controllers that run as watch loops constantly observing the cluster making sure the observed state matches desired state.

