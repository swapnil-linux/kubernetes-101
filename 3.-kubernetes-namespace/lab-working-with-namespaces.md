# Lab: Working with Namespaces

1. Every Kubernetes cluster has a set of pre-created Namespaces (virtual clusters). Run the following command to list yours.

```
$ kubectl get namespaces 
NAME              STATUS   AGE
default           Active   2d22h
kube-node-lease   Active   2d22h
kube-public       Active   2d22h
kube-system       Active   2d22h
```

2\. Run a `kubectl describe` to inspect one of the Namespaces on your cluster.

```
$ kubectl describe ns default
Name:         default
Labels:       kubernetes.io/metadata.name=default
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
[centos@ip-10-0-2-94 ~]$ 
```

{% hint style="info" %}
Note: You can substitute `namespace` with `ns` when working with `kubectl`
{% endhint %}

3\. List Service objects in the `kube-system` Namespace

```
$ kubectl get svc -n kube-system
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   2d22h
[centos@ip-10-0-2-94 ~]$ 
```

4\. Create a new Namespace, called “hydra”, with the following imperative command.

```
$ kubectl create ns hydra
namespace/hydra created
[centos@ip-10-0-2-94 namespaces]$
```

5\. Get the api details for namespaces using the below command

```
$ kubectl api-resources|grep -Ew 'namespaces|NAME'
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
namespaces                        ns           v1                                     false        Namespace
[centos@ip-10-0-2-94 ~]$ 
```

6\. Get the list of fields for namespaces

```
$ kubectl explain ns --recursive 
KIND:     Namespace
VERSION:  v1

DESCRIPTION:
     Namespace provides a scope for Names. Use of multiple namespaces is
     optional.

FIELDS:
   apiVersion	<string>
   kind	<string>
   metadata	<Object>
   ...
   ...
      labels	<map[string]string>
   ..
      name	<string>
```

{% hint style="info" %}
Namespaces are first-class resources in the core v1 API group. This means they’re stable, well understood, and have been around for a long time. It also means you can create and manage them imperatively with kubectl, and declaratively with YAML manifests.
{% endhint %}

7\. Inspect shield-ns.yml file and create it with the following command.

```
$ cat ~/kubernetes-101/labs/ns/shield-ns.yml 
kind: Namespace
apiVersion: v1
metadata:
  name: shield
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl create -f ~/kubernetes-101/labs/ns/shield-ns.yml
namespace/shield created
[centos@ip-10-0-2-94 ~]$ 
```

8\. List all Namespaces to see the two new ones you created.

```
$ kubectl get ns
NAME              STATUS   AGE
...
hydra             Active   28m
shield            Active   31s
...
[centos@ip-10-0-2-94 ~]$ 
```

9\. Delete the “hydra” Namespace.

```
$ kubectl delete ns hydra
namespace "hydra" deleted
[centos@ip-10-0-2-94 ~]$ 
```

{% hint style="info" %}
When you start using Namespaces, you’ll quickly realise it’s painful remembering to add the -n or --namespace flag on all kubectl commands. A better way might be to set your kubeconfig to automatically work with a particular Namespace.
{% endhint %}

10\. The following command configures kubectl to run all future commands against the shield Namespace.

Get the list of contexts

```
$ kubectl config get-contexts 
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   default
[centos@ip-10-0-2-94 ~]$ 
```

Change the current context

```
$ kubectl config set-context --current --namespace shield
Context "kubernetes-admin@kubernetes" modified.
[centos@ip-10-0-2-94 ~]$ 
```

List it again and notice the change in NAMESPACE column

```
$ kubectl config get-contexts 
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   shield
[centos@ip-10-0-2-94 ~]$
```

11\. We’ll declaratively deploy a simple app to the shield Namespace and test it. Notice the namespace filed in the `shield-app.yml`

```
$ kubectl create -f ~/kubernetes-101/labs/ns/shield-app.yml 
service/the-bus created
pod/triskelion created
[centos@ip-10-0-2-94 ~]$
```

`12.` Run a few commands to verify all three objects were deployed to the shield Namespace.

```
$ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
triskelion   1/1     Running   0          45s
```

```
$ kubectl get svc
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
the-bus   NodePort   10.111.204.77   <none>        8080:31112/TCP   49s
```

```
$ curl localhost:31112
Server IP: 10.85.0.14 
```

13\. Switch back the context to the default namespace, and run the below commands to list the pods from the shield namespace

```
$ kubectl config set-context --current --namespace default
Context "kubernetes-admin@kubernetes" modified.
```

```
$ kubectl get pods 
No resources found in default namespace.
```

```
$ kubectl get pods -n shield
NAME         READY   STATUS    RESTARTS   AGE
triskelion   1/1     Running   0          4m4s
[centos@ip-10-0-2-94 ~]$ 
```

14\. Clean Up

```
$ kubectl delete all --all -n shield 
pod "triskelion" deleted
service "the-bus" deleted
```

```
$ kubectl delete ns shield
namespace "shield" deleted
[centos@ip-10-0-2-94 ~]$ 
```

_**That was really good ✌️**_&#x20;
