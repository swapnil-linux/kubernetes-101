# 4. Working with Pods

Pods are fundamental to running apps on Kubernetes. As such, this chapter goes into quite a bit of detail.

Before getting started, it’s difficult to talk about Pods without referring to workload controllers such as Deployments, DaemonSets, and StatefulSets. However, this is the start of the book and we haven’t covered any of those yet. So, we’ll take a quick minute here to set the scene so that when they come up in the chapter, you’ll have a basic idea of what they are.

You’ll almost always deploy Pods via higher-level workload controllers – from now on, we’ll just call them controllers.

Controllers infuse Pods with super-powers such as self-healing, scaling, rollouts and rollbacks. You’ll see this later, but every controller has a PodTemplate defining the Pods it deploys and manages. So, even though you’ll rarely interact directly with Pods, it’s absolutely vital you have a solid understanding of them.

For these reasons, we’ll cover quite a lot of Pod detail. It won’t be wasted time and it’ll be very useful as you progress to controllers and other more advanced objects. Also, a deep understanding of Pods is vital if you want to master Kubernetes.

With that out of the way, let’s crack on.

## Pod theory

The atomic unit of scheduling in Kubernetes is the Pod. This is just a fancy way of saying apps deployed to Kubernetes always run inside Pods.

Some quick examples... If you deploy an app, you deploy it in a Pod. If you terminate an app, you terminate its Pod. If you scale an app up or down, you add or remove Pods.

### Why Pods

The process of building and running an app on Kubernetes is roughly as follows:

1\. Write your app/code\
2\. Package it as a container image\
3\. Wrap the container image in a Pod 4. Run it on Kubernetes

This begs the question, why not just run the container on Kubernetes?\
The short answer is you just can’t. Kubernetes doesn’t allow containers to run directly on

a cluster, they always have to be wrapped in a Pod. Broadly speaking, there are three main reasons for Pods.

1\. Pods augment containers\
2\. Pods assist in scheduling\
3\. Pods enable resource sharing

Let’s look closer at each.

#### Pods augment containers

On the augmentation front, Pods augment containers in all the following ways.

• Labels and annotations\
• Restart policies\
• Probes (startup probes, readiness probes, liveness probes, and potentially more) • Affinity and anti-affinity rules\
• Termination control\
• Security policies\
• Resource requests and limits

Run a `kubectl explain pods --recursive` command to list all possible Pod attributes. Beware, the command returns over 1,000 lines and the following output has been trimmed.

```
KIND:     Pod
VERSION:  v1

DESCRIPTION:
     Pod is a collection of containers that can run on a host. This resource is
     created by clients and scheduled onto hosts.

FIELDS:
   apiVersion	<string>
   kind	<string>
   metadata	<Object>
      annotations	<map[string]string>
      clusterName	<string>
      creationTimestamp	<string>
      deletionGracePeriodSeconds	<integer>
      deletionTimestamp	<string>
      finalizers	<[]string>
      generateName	<string>
      generation	<integer>
      labels	<map[string]string>
      managedFields	<[]Object>
         apiVersion	<string>
         fieldsType	<string>
         fieldsV1	<map[string]>
         manager	<string>
         operation	<string>
         subresource	<string>
```

It’s a useful command for finding which properties any object supports. It also shows the format of properties, such as whether it’s a string, map, object, or something else.

Even more useful, is the ability to drill into specific attributes. The following command drills into the restart policy attribute of a Pod object.

```
[centos@ip-10-0-2-94 ~]$ kubectl explain pod.spec.restartPolicy
KIND:     Pod
VERSION:  v1

FIELD:    restartPolicy <string>

DESCRIPTION:
     Restart policy for all containers within the pod. One of Always, OnFailure,
     Never. Default to Always. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy

     Possible enum values:
     - `"Always"`
     - `"Never"`
     - `"OnFailure"`
[centos@ip-10-0-2-94 ~]$ 
```

* _Labels_ let you group Pods and associate them with other objects in powerful ways.&#x20;
* _Annotations_ let you add experimental features and integrations with 3rd-party tools\
  and services.&#x20;
* _Probes_ let you test the health and status of Pods and the apps they run. This enables advanced scheduling, updates, and more.&#x20;
* _Affinity and anti-affinity_ rules give you control over where in a cluster Pods are allowed to run.
* _Termination control_ lets you to gracefully terminate Pods and the applications they run.&#x20;
* _Security policies_ let you enforce security features.&#x20;
* _Resource requests and limits_ let you specify minimum and maximum values for things like CPU, memory, and disk IO.

Despite bringing so many features to the party, Pods are super-lightweight and add very little overhead.

![Pod as a wrapper around one or more containers](<../.gitbook/assets/Screen Shot 2022-06-21 at 8.30.51 am.png>)

#### Pods assist in scheduling

On the scheduling front, every container in a Pod is guaranteed to be scheduled to the same worker node. This in turn guarantees they’ll be in the same region and zone in your cloud or datacenter. We call this co-scheduling and co-locating.

Labels, affinity and anti-affinity rules, and resource requests and limits give you fine- grained control over which worker nodes Pods can run on.

#### Pods enable resource sharing

On the sharing of resources front, Pods provide a shared execution environment for one or more containers. This shared execution environment includes things such as.

• Shared filesystem (mnt namespace)

• Shared network stack like IP address, routing table, ports. (net namespace)

• Shared memory (IPC namespace)

• Shared volumes

You’ll see it later, but every container in a Pod shares the Pod’s execution environment. So, if a Pod has two containers, both containers share the Pod’s IP address and can access any of the Pod’s volumes to share data.

### Static Pods vs controllers

There are two ways to deploy Pods.

1\. Directly via a Pod manifest&#x20;

2\. Indirectly via a controller

Pods deployed directly from a Pod manifest are called static Pods and have no super- powers such as self-healing, scaling, or rolling updates. This is because they’re only monitored and managed by the worker node’s kubelet process which is limited to attempting container and Pod restarts on the local worker node. If the worker node they’re running on fails, there’s no control-plane process watching and capable of starting a new one on a different node.

Pods deployed via controllers have all the benefits of being monitored and managed by a highly-available controller running on the control-plane. The local kubelet can still attempt local restarts, but if restart attempts fail, or the node itself fails, the observing controller can start a replacement Pod on a different worker node.

Just to be clear, it’s vital to understand that Pods as mortal. When they die, they’re gone. There’s no fixing them and bringing them back from the dead. This firmly places them in the cattle category of the pets vs cattle paradigm. Pods are cattle, and when they die, they get replaced by another. There’s no tears and no funeral. The old one is gone, and a shiny new one – with the same config, but a different IP address and UID – magically appears and takes its place.

This is why applications should always store state and data outside the Pod. It’s also why you shouldn’t rely on individual Pods – they’re ephemeral, here today, gone tomorrow...

In the real world, you’ll almost always deploy and manage Pods via controllers.

### Deploying Pods

The process of deploying a Pod to Kubernetes is as follows.

1. Define it in a YAML manifest file&#x20;
2. Post the YAML to the API server
3. The API server authenticates and authorizes the request
4. The configuration (YAML) is validated
5. The scheduler deploys the Pod to a healthy worker node with enough available resources
6. The local kubelet monitors it

If the Pod is deployed via a controller, the configuration will be added to the cluster store as part of overall desired state and a controller will monitor it.

### The anatomy of a Pod

At the highest level, a Pod is an execution environment shared by one or more containers. Shared execution environment means the Pod has a set of resources that are shared by every container it runs. These resources include IP address, ports, hostname, sockets, memory, volumes, and more...

It can be useful to think of Pods as shared environments, and containers as application processes.

If you’re using Docker or containerd as your container runtime, a Pod is actually a special type of container called a “pause container”. You heard that right, a Pod is just a fancy name for a special container. This means containers running inside of Pods are really containers running inside of containers. For more information, watch “Inception” by Christopher Nolan, starring Leonardo DiCaprio ;-)

Seriously though, a Pod is a collection of resources that any containers it runs inherit and share. These resources are actually Linux kernel namespaces, and include the following:

• net namespace: IP address, port range, routing table...&#x20;

• pid namespace: isolated process tree

• mnt namespace: filesystems and volumes...

• UTS namespace: Hostname

• IPC namespace: Unix domain sockets and shared memory

As a quick example, let’s look at how the Pod shared execution environment model affects networking.

### Pods and shared networking

Each Pod creates its own network namespace. This means a Pod has its own IP address, a single range of TCP and UDP ports, and a single routing table. If it’s a single-container Pod, the container has full access to the IP, port range and routing table. If it’s a multi- container Pod, all containers share the IP, port range and routing table.

![This shows two Pods, each with its own IP. Even though one of them is a multi- container Pod, it still only gets a single IP.](<../.gitbook/assets/Screen Shot 2022-06-21 at 8.57.06 am.png>)

External access to the containers in the Pod on the left is achieved via the IP address of the Pod coupled with the port of the container you’re trying to reach. For example, 10.0.10.15:80 will get you to the main application container, but 10.0.10.15:5000 will get you to the supporting container.

Container-to-container communication within the same Pod happens via the Pod’s localhost adapter and a port number. For example, the main container can reach the supporting container on localhost:5000.

### The pod network

On the topic of networking, every Pod gets its own unique IP addresses that’s fully routable on an internal Kubernetes network called the pod network. The pod network is flat, meaning every Pod can talk directly to every other Pod without the need for complex routing and port mappings.

![Inter-Pod communication](<../.gitbook/assets/Screen Shot 2022-06-21 at 8.59.46 am.png>)

### Atomic deployment of Pods

Pod deployment is an atomic operation. This means it’s all-or-nothing – deployment either succeeds or it fails. You’ll never have a scenario where a partially deployed Pod is servicing requests. Only after all a Pod’s containers and resources are running and ready will it start servicing requests.

### Pod lifecycle

The lifecycle of a typical Pod is something like this...

You define it in a declarative YAML object that you post to the API server and it enters the pending phase. It’s then scheduled to a healthy worker node with enough resources and the local kubelet instructs the container runtime to pull all required images and start all containers. Once all containers are pulled and running, the Pod enters the running phase. If it’s a short-lived Pod, as soon as all containers terminate successfully the Pod itself terminates and enters the succeeded state. If it’s a long-lived Pod, it remains indefinitely in the running phase.

### Shorted-lived and long-lived Pods

Pods can run all different types of applications. Some, such as web servers, are intended to be long-lived and should remain in the running phase indefinitely. If any containers in a long-lived Pod fail, the local kubelet may attempt to restart them.

We say the kubelet “may” attempt to restart them. This is based on the container’s restart policy which is defined in the Pod config. Options include Always, OnFailure, and Never. Always is the default restart policy and appropriate for most long-lived Pods.

Other workload types, such as batch jobs, are designed to be short-lived and only run until a task completes. Once all containers in a short-lived Pod successfully terminate, the Pod terminates and its status is set to successful. Appropriate container restart policies for short-lived Pods will usually be Never or OnFailure.

Kubernetes has several controllers for different types of long-lived and short-lived workloads. Deployments, StatefulSets, and DaemonSets are examples of controllers designed for long-lived Pods. Jobs and CronJobs are examples designed for short-lived Pods.

### Pod immutability

Pods are immutable objects. This means you can’t modify them after they’re deployed.

This can be quite a mindset change, especially if you come from a background of deploying servers and regularly logging on to them to patch and update them.

The immutable nature of Pods is a key aspect of cloud-native microservices design patterns and forces the following behaviors.

• When updates are needed, replace all old Pods with new ones that have the updates&#x20;

• When failures occur, replace failed Pods with new ones

To be clear, you never actually update a running Pod, you always replace it with a new Pod containing the updates. You also never log onto failed Pods and attempt fixes; you build fixes into an updated Pod and replace failed ones with the updated one.

### Pods and scaling

All Pods run a single application container instance, making them an ideal unit of scaling – if you need to scale the app, you add or remove Pods. This is called horizontal scaling.

You never scale an app by adding more of the same application containers to a Pod. Multi-container Pods are only for co-scheduling and co-locating containers that need tight coupling, they’re not a way to scale an app.
