# 3. Kubernetes Namespace

You may have heard about Linux namespace which are used to isolate system processes from each other. In a similar concept we have namespace in Kubernetes which can provide a scope for objects names.&#x20;

### Understanding Kubernetes Namespaces

* Kubernetes uses namespaces to organize objects in the cluster.
* You can think of each namespace as a folder that holds a set of objects.
* Namespace implements strict resource separation
* Resource limitation through quota can be implemented at a Namespace level&#x20;
* Use namespaces to separate  environments within one Kubernetes cluster
* By default, the `kubectl` command-line tool interacts with the default namespace.
* If you want to use a different namespace, you can pass `kubectl` the `--namespace` flag.
* For example, `kubectl --namespace=mystuff` references objects in the `mystuff` namespace.
* If you want to interact with all namespaces - for example, to list all Pods in your cluster you can pass the `--all-namespaces` flag.

Four namespaces are defined when a cluster is created:

* **default:** this is where all the Kubernetes resources are created by default
* **kube-node-lease:** an administrative namespace where node lease information is stored - may be empty and/or non-existing
* **kube-public:** a namespace that is world-readable. Generic information can be stored here but it's often empty
* **kube-system:** contains all infrastructure pods

### Why do we need namespaces?

Using multiple namespaces allows you to split complex systems with numerous components into smaller distinct groups. This is useful in scenarios wherein you want to split and limit resources across different resources. Resource names only need to be unique within a namespace. Two different namespaces can contain resources of the same name.

Although namespaces allow you to isolate objects into distinct groups, which allows you to operate only on those belonging to the specified namespace, they don’t provide any kind of isolation of running objects. For example, you may think that when different users deploy pods across different namespaces, those pods are isolated from each other and can’t communicate, but that’s not necessarily the case. Whether namespaces provide network isolation depends on which networking solution is deployed with Kubernetes. When the solution doesn’t provide inter-namespace network isolation, if a pod in namespace foo knows the IP address of a pod in namespace bar, there is nothing preventing it from sending traffic, such as HTTP requests, to the other pod.

&#x20;

### List available namespaces

To get the list of available namespaces.&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl get ns
NAME              STATUS   AGE
default           Active   61m
kube-node-lease   Active   61m
kube-public       Active   61m
kube-system       Active   61m
[centos@ip-10-0-2-94 ~]$ 
[centos@ip-10-0-2-94 ~]$ 
[centos@ip-10-0-2-94 ~]$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   61m
kube-node-lease   Active   61m
kube-public       Active   61m
kube-system       Active   61m
[centos@ip-10-0-2-94 ~]$ 


```

To get list of all objects across all namespaces use the below command.

```
[centos@ip-10-0-2-94 ~]$ kubectl get all --all-namespaces
NAMESPACE     NAME                                                                       READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-6d4b75cb6d-64cbt                                               1/1     Running   0          62m
kube-system   pod/coredns-6d4b75cb6d-kv22t                                               1/1     Running   0          62m
kube-system   pod/etcd-ip-10-0-2-94.ap-southeast-2.compute.internal                      1/1     Running   0          62m
kube-system   pod/kube-apiserver-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          62m
kube-system   pod/kube-controller-manager-ip-10-0-2-94.ap-southeast-2.compute.internal   1/1     Running   0          62m
kube-system   pod/kube-proxy-tlftd                                                       1/1     Running   0          62m
kube-system   pod/kube-scheduler-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          62m

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  62m
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   62m

NAMESPACE     NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   62m

NAMESPACE     NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns   2/2     2            2           62m

NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-6d4b75cb6d   2         2         2       62m
[centos@ip-10-0-2-94 ~]$ 

```

To list the pods from a specific namespace, for example to list all the pods under `kube-system` namespace we can use the below command:

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n kube-system
NAME                                                                   READY   STATUS    RESTARTS   AGE
coredns-6d4b75cb6d-64cbt                                               1/1     Running   0          63m
coredns-6d4b75cb6d-kv22t                                               1/1     Running   0          63m
etcd-ip-10-0-2-94.ap-southeast-2.compute.internal                      1/1     Running   0          63m
kube-apiserver-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          63m
kube-controller-manager-ip-10-0-2-94.ap-southeast-2.compute.internal   1/1     Running   0          63m
kube-proxy-tlftd                                                       1/1     Running   0          63m
kube-scheduler-ip-10-0-2-94.ap-southeast-2.compute.internal            1/1     Running   0          63m
[centos@ip-10-0-2-94 ~]$ 
```

### Creating a namespace

A namespace is a Kubernetes resource like any other, so you can create it by using a YAML file or directly via `kubectl` command. You can run the following command to see all Kubernetes API resources (objects) supported by your cluster. The output displays whether an object is namespaced or not.

#### Using YAML file

To create a Kubernetes namespace using YAML file we would need the `KIND` and `apiVersion`. To get the `KIND` value of a namespace we will list down the `api-resources`:

```
[centos@ip-10-0-2-94 ~]$ kubectl api-resources | grep -iE 'namespace|KIND'
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
namespaces                        ns           v1                                     false        Namespace
[centos@ip-10-0-2-94 ~]$ 
```

Now that we have the KIND and `apiVersion`, we can construct our yaml file with the following listing’s contents:

```
[centos@ip-10-0-2-94 ~]$ cat app-ns.yml 
apiVersion: v1
kind: Namespace
metadata:
   name: app
[centos@ip-10-0-2-94 ~]$ 
```

Now, use `kubectl` to post the file to the Kubernetes API server:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f app-ns.yml 
namespace/app created
[centos@ip-10-0-2-94 ~]$
```

List the available namespaces:

```
[centos@ip-10-0-2-94 ~]$ kubectl get ns
NAME              STATUS   AGE
app               Active   14s
default           Active   69m
kube-node-lease   Active   69m
kube-public       Active   69m
kube-system       Active   69m
[centos@ip-10-0-2-94 ~]$ 
```

#### Using kubectl command

Although writing a file like the previous one isn’t a big deal, it’s still a hassle. Luckily, you can also create namespaces with the dedicated `kubectl create namespace` command, which is quicker than writing a YAML file. To create a namespace using `kubectl` command:

```
[root@controller ~]# kubectl create ns dev
namespace/dev created
```

List the available namespace:



```
[root@controller ~]# kubectl get ns
NAME               STATUS   AGE
app                Active   2m12s
default            Active   37d
dev                Active   2s
kube-node-lease    Active   37d
kube-public        Active   37d
kube-system        Active   37d
pods-quota-ns      Active   36d
```

&#x20;

#### Get details of namespace

To get a much detailed output of individual namespace we use `kubectl describe` command. As you can see currently there are no quota or `LimitRange` assigned to this namespace which we will cover in [How to assign Kubernetes resource quota with examples](https://www.golinuxcloud.com/kubernetes-resource-quota/)

```
[root@controller ~]# kubectl describe ns default
Name:         default
Labels:       
Annotations:  
Status:       Active

No resource quota.

No LimitRange resource.
```

To get the details of namespace in YAML format:

```
[root@controller ~]# kubectl get ns default -o yaml
apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: "2020-11-11T05:46:42Z"
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:status:
        f:phase: {}
    manager: kube-apiserver
    operation: Update
    time: "2020-11-11T05:46:42Z"
  name: default
  resourceVersion: "155"
  selfLink: /api/v1/namespaces/default
  uid: e45242f9-2f0e-4bcb-a385-6058044f20ce
spec:
  finalizers:
  - kubernetes
status:
  phase: Active
```

&#x20;

### Create resource objects in other namespaces

BY default any resource object you create such as Pods, deployments or any other objects, all of them are created in default namespace unless you explicitly define the namespace in YAML file or as an input argument to kubectl.

&#x20;

#### Method-1: Using YAML file

In this example I will create a new Pod with `nginx` container and explicitly define the namespace as "app" in the YAML file itself under `metadata`:

```
[root@controller ~]# cat nginx-app.yml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-app
  namespace: app
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

We will create this Pod:

```
[root@controller ~]# kubectl create -f nginx-app.yml
pod/nginx-app created
```

As expected now if we look out for this Pod in default namespace, we get `NotFound`

```
[root@controller ~]# kubectl get pods -n default nginx-app
Error from server (NotFound): pods "nginx-app" not found
```

Because we have created this Pod in `app` namespace:

```
[root@controller ~]# kubectl get pods -n app nginx-app
NAME        READY   STATUS    RESTARTS   AGE
nginx-app   1/1     Running   0          30s
```

&#x20;

#### Method-2: Using kubectl command

We can also pass an input argument to the kubectl command as `-n <namespace-name>` to assign a namespace. Here I have a different YAML file:



```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-dev
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```

We will create this Pod inside "`dev`" namespace:

```
[root@controller ~]# kubectl create -f nginx-dev.yml -n dev
pod/nginx-dev created
```

List the newly created Pod under `dev` namespace:

```
[root@controller ~]# kubectl get pods -n dev
NAME        READY   STATUS    RESTARTS   AGE
nginx-dev   1/1     Running   0          34s
```

HINT:When listing, describing, modifying, or deleting objects in other namespaces, you need to pass the `--namespace` (or `-n`) flag to `kubectl`. If you don’t specify the namespace, `kubectl` performs the action in the default namespace configured in the current `kubectl context`. The current context’s namespace and the current context itself can be changed through kubectl config commands which we will learn later.

&#x20;

### Terminating namespaces

We have created a number of pods and namespaces in this tutorial which we don't need anymore so let's delete them.

&#x20;

#### Deleting a Pod using name

We have already covered this in [Beginners guide on Kubernetes Pods with examples](https://www.golinuxcloud.com/kubernetes-pod/). By deleting a pod, you’re instructing Kubernetes to terminate all the containers that are part of that pod. Kubernetes sends a SIGTERM signal to the process and waits a certain number of seconds (30 by default) for it to shut down gracefully. If it doesn’t shut down in time, the process is then killed through SIGKILL.

```
[root@controller ~]# kubectl delete pod nginx-dev
pod "nginx-dev" deleted
```

&#x20;

#### Deleting pods by deleting the whole namespace

By default when we delete a namespace then all the pods under the provided namespace would also be terminated:

```
[root@controller ~]# kubectl delete ns dev
namespace "dev" deleted
```

&#x20;

#### Deleting all pods in a namespace, while keeping the namespace

Here I have a Pod running inside app namespace:

```
[root@controller ~]# kubectl get pods -n app
NAME        READY   STATUS    RESTARTS   AGE
nginx-app   1/1     Running   0          23m
```

Now to delete all the pods inside app namespace:

```
[root@controller ~]# kubectl delete pods -n app --all
pod "nginx-app" deleted
```

Since we had a single pod so only that one is deleted.

&#x20;

#### Delete all resources in a namespace

You can delete the ReplicationController and the pods, as well as all the Services you’ve created, by deleting all resources in the current namespace with a single command. To demonstrate this command I have created some of the resource objects in `app` namespace:

```
[root@controller ~]# kubectl delete all --all -n app
pod "myapp-replicaset-5hwhc" deleted
pod "myapp-replicaset-hmqj9" deleted
pod "myapp-replicaset-q6m5r" deleted
pod "nginx-deploy-58f9bf94f7-fztpl" deleted
pod "nginx-deploy-58f9bf94f7-qnjhq" deleted
service "nginx-deploy" deleted
deployment.apps "nginx-deploy" deleted
replicaset.apps "myapp-replicaset" deleted
replicaset.apps "nginx-deploy-58f9bf94f7" deleted
```

The first `all` in the command specifies that you’re deleting resources of all types, and the `--all` option specifies that you’re deleting all resource instances instead of specifying them by name.

NOTE:Deleting everything with the all keyword doesn’t delete absolutely everything. Certain resources (like Secrets) are preserved and need to be deleted explicitly.

&#x20;

### Conclusion

In this chapter, you learned that Kubernetes has a technology called Namespaces that can divide a cluster for resource and accounting purposes. Each Namespace can have its own users and RBAC rules, as well as resource quotas. However, they’re not designed as strong boundaries for isolating workloads.

You also learned that many objects are namespaced. If you don’t explicitly target an object at a Namespace, it’ll be deployed to the default Namespace.



