# 2. Deploying Kubernetes Cluster

This section lists the different ways to set up and run Kubernetes. When you install Kubernetes, choose an installation type based on: ease of maintenance, security, control, available resources, and expertise required to operate and manage a cluster.

### Learning environment <a href="#learning-environment" id="learning-environment"></a>

If you're learning Kubernetes, use the tools supported by the Kubernetes community, or tools in the ecosystem to set up a Kubernetes cluster on a local machine.&#x20;

#### kind <a href="#kind" id="kind"></a>

[`kind`](https://kind.sigs.k8s.io/docs/) lets you run Kubernetes on your local computer. This tool requires that you have [Docker](https://docs.docker.com/get-docker/) installed and configured.

The kind [Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) page shows you what you need to do to get up and running with kind.

#### minikube <a href="#minikube" id="minikube"></a>

Like `kind`, [`minikube`](https://minikube.sigs.k8s.io/) is a tool that lets you run Kubernetes locally. `minikube` runs a single-node Kubernetes cluster on your personal computer (including Windows, macOS and Linux PCs) so that you can try out Kubernetes, or for daily development work.

You can follow the official [Get Started!](https://minikube.sigs.k8s.io/docs/start/) guide if your focus is on getting the tool installed.



### Production environment <a href="#production-environment" id="production-environment"></a>

When evaluating a solution for a production environment, consider which aspects of operating a Kubernetes cluster (or _abstractions_) you want to manage yourself and which you prefer to hand off to a provider.

For a cluster you're managing yourself, the officially supported tool for deploying Kubernetes is [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/).

### kubeadm <a href="#kubeadm" id="kubeadm"></a>

You can use the [kubeadm](https://kubernetes.io/docs/admin/kubeadm/) tool to create and manage Kubernetes clusters. It performs the actions necessary to get a minimum viable, secure cluster up and running in a user friendly way.



\
