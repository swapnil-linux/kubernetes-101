# 5. Deployments

In this chapter, you’ll see how to use Deployments to bring cloud-native features such as self-healing, scaling, rolling updates, and versioned rollbacks to stateless apps on Kubernetes. Deployments are extremely useful and you’ll use them all the time.

Kubernetes offers several controllers that augment Pods with important capabilities. The Deployment controller is specifically designed for stateless apps. We’ll cover other controllers later in the course.

Throughout the chapter, we’ll use terms like release, rollout, and rolling update to mean the same thing – pushing a new version of an app.

## Deployment theory

There are two major components to Deployments.

1\. The spec\
2\. The controller

The Deployment spec is a declarative YAML object where you describe the desired state of a stateless app. You give it to Kubernetes where the Deployment controller implements and manages it. The controller element is highly-available and operates as a background loop, on the control plane, reconciling the observed state with the desired state.

The latest version of the Deployment object, including all features and attributes, is defined in the apps/v1 workloads API sub-group.

```
[centos@ip-10-0-2-94 ~]$ kubectl api-resources |grep -Ew 'deployments|NAME'
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
deployments                       deploy       apps/v1                                true         Deployment
[centos@ip-10-0-2-94 ~]$ 
```

You start with a stateless application, package it as a container, then define it in a Pod template. At this point you could run it on Kubernetes. However, static Pods like this don’t self-heal, they don’t scale, and they don’t allow for easy updates and rollbacks. For these reasons, you’ll almost always wrap them in a Deployment object.

![](<../.gitbook/assets/Screen Shot 2022-06-23 at 4.34.50 pm.png>)

You post the Deployment object to the API server where Kubernetes implements it and the Deployment controller watches it.

## Deployments and Pods

A Deployment object only manages a single Pod template. For example, an application with a front-end web service and a shopping basket service will have a different Pod\
for each (two Pod templates). As a result, it’ll need two Deployment objects – one managing front-end web Pods, the other managing any shopping basket Pods. However, a Deployment can manage multiple replicas of the same Pod. For example, the front-end web Deployment might be managing 5 identical replicas of the front-end web Pod.

## Deployments and ReplicaSets

Behind-the-scenes, Deployments rely heavily on another object called a ReplicaSet. While it’s recommended not to manage ReplicaSets directly (let the Deployment controller manage them), it’s important to understand the role they play.

At a high-level, containers are a great way to package applications and dependencies. Pods allow containers to run on Kubernetes and enable co-scheduling and a bunch of other good stuff. ReplicaSets manage Pods and bring self-healing and scaling. Deployments manage ReplicaSets and add rollouts and rollbacks. As a result, working with Deployments brings the benefits of everything else – the container, the Pod, the ReplicaSet.

![](<../.gitbook/assets/Screen Shot 2022-06-23 at 4.37.32 pm.png>)

Think of Deployments as managing ReplicaSets, and ReplicaSets as managing Pods. Put them together, and you’ve got a great way to deploy and manage stateless applications on Kubernetes.

## Self-healing and scalability

Pods are great. They let you co-locate containers, share volumes, share memory, simplify networking, and a lot more. But they offer nothing in the way of self-healing and scalability – if the node a Pod is running on fails, the Pod is lost.

Enter Deployments...

• If Pods managed by a Deployment fail, they will be replaced – _self-healing_\
• If Pods managed by a Deployment see increased or decreased load, they can be _scaled_

Remember though, hidden away behind-the-scenes, it’s actually the ReplicaSets doing the self-healing and scalability. You’ll see them in action soon.

## It’s all about the state

Before going any further, it’s critical to understand three concepts that are fundamental to everything about Kubernetes:

* Desired state
* Observed state (sometimes called actual state or current state)
* Reconciliation

_Desired_ state is what you **want**. _Observed_ state is what you **have**. If they match, everybody’s happy. If they don’t match, a process of _reconciliation_ attempts to bring observed state into **sync** with desired state.

## Rolling updates with Deployments

Zero-downtime rolling-updates (rollouts) of stateless apps are what Deployments are all about, and they’re amazing. However, they require a couple of things from your microservices applications in order to work properly.

1\. Loose coupling via APIs\
2\. Backwards and forwards compatibility

Both of these are hallmarks of modern cloud-native microservices apps and work as follows.

All microservices in an app should be decoupled and only communicate via well-defined APIs. This allows any microservice to be updated without having to think about clients and other microservices that interact with them – everything talks to formalised APIs that expose documented interfaces and hide specifics. Ensuring releases are backwards and forwards compatible means you can perform independent updates without having to factor in which versions of clients are consuming the service. A simple non-tech example is a car. You can swap the engine in a car, change the exhaust, get bigger brakes etc. However, as long as the driving API (steering wheel and foot pedals) doesn’t change, drivers can still drive the car without having to learn any new skills.

With those points in mind, zero-downtime rollouts work like this.

Assume you’re running 5 replicas of a stateless web front-end. As long as all clients communicate via APIs and are backwards and forwards compatible, it doesn’t matter which of the 5 replicas a client connects to. To perform a rollout, Kubernetes creates a new replica running the new version and terminates an existing one running the old version. At this point, you’ve got 4 replicas on the old version and 1 on the new. This process repeats until all 5 replicas are on the new version. As the app is stateless, and there are always multiple replicas up and running, clients experience no downtime or interruption of service.

There’s actually a lot that goes on behind the scenes, so let’s look a bit closer.

You design applications with each discrete microservice as its own Pod. For convenience – self-healing, scaling, rolling updates and more – you wrap the Pods in their own higher-level controller such as a Deployment. Each Deployment describes all the following:

• How many Pod replicas\
• What images to use for the Pod’s containers\
• What network ports to expose\
• Details about how to perform rolling updates

In the case of Deployments, when you post the YAML file to the API server, the Pods get scheduled to healthy nodes and a Deployment and ReplicaSet work together to make the magic happen. The ReplicaSet controller sits in a watch loop making sure our old friends observed state and desired state are in agreement. A Deployment object sits above the ReplicaSet, governing its configuration and providing mechanisms for rollouts and rollbacks.

This diagram shows a Deployment that’s been updated once. The initial release created the ReplicaSet on the left, and the update created the one on the right. You can see the ReplicaSet for the initial release has been wound down and no longer manages any Pods. The one for the update is active and owns all the Pods.

![](<../.gitbook/assets/Screen Shot 2022-06-24 at 11.44.38 am.png>)

It’s important that the old ReplicaSet from the initial release still exists with its configuration intact. You’ll see why in the next section.

## Rollbacks

As you saw in the above diagram, older ReplicaSets are wound down and no longer manage any Pods. However, their configurations still exist on the cluster, making them a great option for reverting to previous versions.

The process of a rollback is the opposite of a rollout – you wind one of the old ReplicaSets up while you wind the current one down. Simple.

![](<../.gitbook/assets/Screen Shot 2022-06-24 at 11.46.47 am.png>)

Let’s see all this stuff in action.
