# 12. Limit Kubernetes Resources

A pod definition can include both resource requests and resource limits:

## Resource requests

Used for scheduling and to indicate that a pod cannot run with less than the specified amount of compute resources. The scheduler tries to find a node with sufficient compute resources to satisfy the pod requests.

## Resource limits

Used to prevent a pod from using up all compute resources from a node. The node that runs a pod configures the Linux kernel `cgroups` feature to enforce the pod's resource limits.

Resource request and resource limits should be defined for each container in `deployment` resource. If requests and limits have not been defined, then you will find a `resources: {}` line for each container.

Modify the `resources: {}` line to specify the desired requests and or limits. For example:

```
    spec:
      containers:
      - image: nginx:lateset
        name: hello
        resources:
          requests:
            cpu: "10m"
            memory: 20Mi
          limits:
            cpu: "80m"
            memory: 100Mi
status: {}
```

you can use the `kubectl set resources` command to specify resource requests and limits. The following command sets the same requests and limits as the preceding example:

```
kubectl set resources deployment nginx --limits=cpu=200m,memory=512Mi --requests=cpu=100m,memory=256Mi
```

## Resource Quotas

Kubernetes can enforce quotas that track and limit the use of two kinds of resources:

### Object counts

The number of Kubernetes resources, such as pods and services.

### Compute resources

The number of physical or virtual hardware resources, such as CPU, memory, and storage capacity.

Imposing a quota on the number of Kubernetes resources improves the stability of the control plane by avoiding unbounded growth of the Etcd database. Quotas on Kubernetes resources also avoids exhausting other limited software resources, such as IP addresses for services.

In a similar way, imposing a quota on the amount of compute resources avoids exhausting the compute capacity of a single node. It also avoids having one application starve other applications in a shared cluster by using all the cluster capacity.

Kubernetes manages quotas for the number of resources and the use of compute resources in a cluster by using a `ResourceQuota` resource, or a `quota`. A quota specifies hard resource usage limits for a project. All attributes of a quota are optional, meaning that any resource that is not restricted by a quota can be consumed without bounds.

The following listing show a `ResourceQuota` resource defined using YAML syntax. This example specifies quotas for both the number of resources and the use of compute resources:

```
apiVersion: v1
kind: ResourceQuota
metadata:
  creationTimestamp: null
  name: my-quota
spec:
  hard:
    cpu: "500m"
    memory: 1Gi
    pods: "2"
    services: "3"
status: {}
```

Resource units are the same for pod resource requests and resource limits. For example, Gi means GiB, and m means millicores. One millicore is the equivalent to 1/1000 of a single CPU core.

Another way to create a resource quota is by using the `kubectl create quota` command, for example:

```
kubectl create quota my-quota --hard=cpu=500m,memory=1Gi,pods=2,services=3
```

