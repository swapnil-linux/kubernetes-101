# minikube

If you want a playground to study Kubernetes, **Minikube** and **Kind** can help you spin up a Kubernetes cluster in minutes.

### Overview on Minikube

**Minikube** is a tool that can set up a **single-node cluster**, and it provides handy commands and parameters to configure the cluster. It primarily aims to provide a local testing environment. It packs a VM containing all the core components of Kubernetes that get installed onto your host machine, all at once. This allows it to support any operating system, as long as a virtualization tool (also known as a **Hypervisor**) is pre-installed.

&#x20;

### Minikube Architecture

As we learned in our previous tutorial, a Kubernetes cluster consists of a controller and worker node, where both node types have their own set of components. But since Minikube is a single node cluster, it will contain all the cluster components inside this single node, which would look something like the following:

![](<../../.gitbook/assets/image (4).png>)

### Pre-requisites

The **minimum resource requirement** for your physical host:

* 2 CPUs or more
* Minimum 2GB of free memory
* Minimum 20GB of free disk space

Additionally, **your host must have:**

* Working internet connection
* Virtualization technology must be enabled in BIOS to support hypervisor
* Anyone of the supported hypervisor

The following are the most common **Hypervisors** supported by Minikube:

* VirtualBox (works for all operating systems)
* KVM (Linux-specific)
* Hyperkit (macOS-specific)
* Hyper-V (Windows-specific)
