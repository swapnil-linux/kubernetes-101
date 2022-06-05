# Overview of Containers

Kubernetes is also known as K8s was created by Google based on their experience from containers in production. It is an open source project and one of the best and most popular container orchestration technology.

Before we understand Kubernetes, we must be familiar with Docker containers or else if you are a beginner then you may find Kubernetes a little confusing to understand. So we will start our Kubernetes 101 by first understanding Containers.



### What are Containers and why you should use them?



* In a normal IT work flow developers would develop a new application. Once the application development was completed, they would hand over that application over to the operations engineers, who were then supposed to install it on the production servers and get it running.
* If the operations engineers were lucky, they even got a somewhat accurate document with installation instructions from the developers. So far, so good, and life was easy.
* But things get a bit out of hand when, in an enterprise, there are many teams of developers that create quite different types of application, yet all of them need to be installed on the same production servers and kept running there.

![](<../.gitbook/assets/image (7).png>)

* Usually, each application has some external dependencies, such as which framework it was built on, what libraries it uses, and so on. Sometimes, two applications use the same framework but in different versions that might or might not be compatible with each other.
* So, installing a new version of a certain application can be a complex project on its own, and often needed months of planning and testing
* But these days we have to release a patch, update very often so this development and testing cycle **can be very risky** to the business.

#### Using Virtual Machine

The first solution was using **Virtual Machines** (VMs)

![](<../.gitbook/assets/image (5).png>)

* Instead of running multiple applications, all on the same server, companies would package and **run a single application on each VM**
* With this, all the compatibility problems were gone and life seemed to be good again.
* But this comes with it's own set of demerits where each VM needs a lot of resources where most is used by underlying system OS.

#### Using Containers

The ultimate solution to this problem was to provide something that is much more lightweight than VMs - **Docker container** to the rescue.

![](<../.gitbook/assets/image (4).png>)



* Instead of virtualizing hardware, containers rest on top of single Linux instance. This allows Docker to leave behind a lot of bloat associated with full hardware hypervisor.
* **Don't mistake** Docker Engine (or the LXC process) as the equivalent of a hypervisor in more traditional VM, it is simply encapsulating process on the underlying system.
* Docker utilizes the **namespace** feature of Linux kernel wherein the namespaces will make the processes that are running within one container are invisible for processors, or users running within another container
* With docker, developers would now package their application, dependent libraries, framework in a container to the testers or operation engineer.
* To testers and operations engineers, a container is just a black box, and all they need is a Linux OS with Docker running and they can easily deploy the container without having to worry about configuring the application as these containers already contain an up and running application.

### Virtual Machine vs Docker Containers

The image should be self explanatory to understand the difference between **Docker and VMware** architecture.\


![](<../.gitbook/assets/image (2).png>)

* VM requires an Hypervisor which can be either installed on an operating system or directly on the hardware while a container can be deployed after installing docker.
* VM requires a separating OS to be installed to deploy your application while Docker containers share the host operating system, and that is why they are lightweight
* Since Docker shares OS with host, the boot up time of docker container is very less while it is comparatively higher for VMs
* The docker containers share Linux kernel so it would be a good fit if you are planning to run multiple applications on the same Linux kernel but if you have applications that require different operating system then you will have to go for VM
* Since VM does not share the host OS it is comparatively more secure than Docker containers. An attacker may exploit all the containers if it gets access to the host or any single container.
* Since containers don't have OS they use comparatively very less resources to execute the application and you can utilize the underlying resources more effectively.

### Container Orchestration

Now that you are familiar with containers, next we need to learn about **container orchestration**. Just to summarise we have a docker container with certain applications running inside the container.

![](<../.gitbook/assets/image (8).png>)

* It is possible that your application from container 1 is dependent on some other application from another container such as database, message, logging service in the production environment.
* You may also need the ability to scale up the number of containers during peak time, for example I am sure you must be familiar with Amazon sale during holidays when they have a bunch of extra offers on all products. In such case they need to **scale up** their resources for applications to be able to handle more number of users. Once the festive offer is finished then they would again need to **scale down** the amount of containers with applications.
* To enable this functionality we need an underlying platform with a set of resources and capabilities. The platform needs to **orchestrate** the connectivity between the containers and automatically scale up or down based on the load.
* This while process of deploying and managing containers is known as **container orchestration**
* **Kubernetes is thus a container orchestration technology** used to orchestrate the deployment and management of hundreds and thousands of containers in a cluster environment.
* There are multiple similar technologies available today, docker has it's own orchestration software i.e. Docker Swarm, Kubernetes from Google and Mesos from Apache.

![](<../.gitbook/assets/image (6).png>)



* Your application is now **highly available** as now we have multiple instances of your application across multiple nodes
* The user traffic is load balanced across various containers
* When demand increases deploy more instances of the applications seamlessly and within a matter of seconds and we have the ability to do that at a service level when we run out of hardware resources then scale the number of underlying nodes up and down without taking down the application and this all can be done easily using a set of declarative object configuration file.

