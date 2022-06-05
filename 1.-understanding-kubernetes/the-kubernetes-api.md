# Container Runtime Interface (CRI/CRI-O)

Docker kicked off the explosion in containers, but soon afterwards, the landscape seemed to explode with tools, standards and acronyms. So what is ‘docker’ really, and what do the terms like “CRI” and “OCI” mean? &#x20;

**Containers are no longer tightly coupled with the name Docker.** You can be running containers with Docker, or a bunch of other tools which **aren’t** Docker. `docker` is just one of the many options, and Docker (the company) backs some of the tools in the ecosystem, but not all.

So if you were thinking that containers are just about Docker, then continue reading! We’ll look at the ecosystem around containers and what each part does. This is especially useful if you’re thinking of moving into DevOps.

The main standards around containers that you should be aware of (although you don’t need to know all the details) are:

* The **Open Container Initiative (OCI)** which publishes specifications for containers and their images.
* The Kubernetes **Container Runtime Interface (CRI)**, which defines an API between Kubernetes and a container runtime underneath.

This illustration shows exactly how Docker, Kubernetes, CRI, OCI, containerd and runc fit together in this ecosystem:

![](<../.gitbook/assets/image (3).png>)

### Container Runtime Interface (CRI) <a href="#container-runtime-interface-cri" id="container-runtime-interface-cri"></a>

**CRI is the protocol that Kubernetes uses to control the different runtimes that create and manage containers.**

CRI is an abstraction for any kind of container runtime you might want to use. So CRI makes it easier for Kubernetes to use different container runtimes.

Instead of the Kubernetes project needing to manually add support for each runtime, the CRI API describes how Kubernetes interacts with each runtime. So then, it’s down to the runtime to actually manage containers. As long as it obeys the CRI API, it can do whatever it likes.

![](<../.gitbook/assets/image (4) (1).png>)

So if you prefer to use _containerd_ to run your containers, you can. Or, if you prefer to use _CRI-O_, then you can. This is because both of these runtimes implement the CRI specification.

If you’re an end user (like a developer), the implementation mostly shouldn’t matter. There are subtle differences between different CRI implementations but they are intended to be pluggable and seamlessly changeable.

**Your choice of runtime might be important if you pay to get support (security, bug fixes etc) from a vendor.** For example, Red Hat’s OpenShift uses _CRI-O_, and offers support for it. Docker provides support for their own _containerd_.

#### **How to check your container runtime in Kubernetes**

In Kubernetes architecture, the _kubelet_ (the agent that runs on each node) is responsible for sending instructions to the container runtime to start and run containers.

You can check which container runtime you’re using by looking at the _kubelet_ parameters on each node. There’s an option `--container-runtime` and `--container-runtime-endpoint` which are used to configure which runtime to use.

#### containerd <a href="#containerd" id="containerd"></a>

`containerd` is a high-level container runtime that came from Docker, and implements the CRI spec. It pulls images from registries, manages them and then hands over to a lower-level runtime, which actually creates and runs the container processes.

_containerd_ was separated out of the Docker project, to make Docker more modular.

So Docker uses _containerd_ internally itself. When you install Docker, it will also install _containerd_.

_containerd_ implements the Kubernetes Container Runtime Interface (CRI), via its _cri_ plugin.

### CRI-O <a href="#cri-o" id="cri-o"></a>

**CRI-O is another high-level container runtime which implements the Container Runtime Interface (CRI). It’s an alternative to **_**containerd**_**. It pulls container images from registries, manages them on disk, and launches a lower-level runtime to run container processes.**

Yes, CRI-O is another container runtime. It was born out of Red Hat, IBM, Intel, SUSE and others.

It was specifically created from the ground up as a container runtime for Kubernetes. It provides the ability to start, stop and restart containers, just like _containerd_.

### Open Container Initiative (OCI) <a href="#open-container-initiative-oci" id="open-container-initiative-oci"></a>

**The OCI is a group of tech companies who maintain a specification for the container image format, and how containers should be run.**

The idea behind the OCI is that you can choose between different runtimes which conform to the spec. Each of these runtimes have different lower-level implementations.

For example, you might have one OCI-compliant runtime for your Linux hosts, and one for your Windows hosts.

This is the benefit of having one standard that can be implemented by many different projects. This same “one standard, many implementations” approach is in use everywhere, from Bluetooth devices to Java APIs.

#### runc <a href="#runc" id="runc"></a>

[**runc**](https://github.com/opencontainers/runc) **is an OCI-compatible container runtime. It implements the OCI specification and runs the container processes.**

_runc_ is called the _reference implementation_ of OCI.

_runc_ provides all of the low-level functionality for containers, interacting with existing low-level Linux features, like namespaces and control groups. It uses these features to create and run container processes.

A couple of alternatives to **runc** are:

* [**crun**](https://github.com/containers/crun) a container runtime written in **C** (by contrast, runc is written in Go.)
* [**kata-runtime**](https://github.com/kata-containers/runtime) from the [Katacontainers](https://katacontainers.io/) project, which implements the OCI specification as individual lightweight VMs (hardware virtualisation)
* [**gVisor**](https://gvisor.dev/) from Google, which creates containers that have their own kernel. It implements OCI in its runtime called `runsc`.

