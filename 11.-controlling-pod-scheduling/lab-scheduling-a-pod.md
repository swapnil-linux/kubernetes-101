# Lab: Scheduling a pod

1. Create a pod with `nodeSelector` as `disktype=ssd`

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/scheduling/pod.yml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: hello
  name: hello
  namespace: myapp
spec:
  containers:
  - image: quay.io/mask365/scaling:latest
    name: hello
    ports:
    - containerPort: 8080
    resources: {}
  dnsPolicy: ClusterFirst
  nodeSelector:
    disktype: ssd
  restartPolicy: Always
```

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/scheduling/pod.yml
pod/hello created
```

2\. check the pod status, it should be in a pending state as we do not have a not with the required label.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods 
NAME    READY   STATUS    RESTARTS   AGE
hello   0/1     Pending   0          82s
```

3\. `kubectl get events` should show more info about the issue

```
[centos@ip-10-0-2-94 ~]$ kubectl get events
LAST SEEN   TYPE      REASON             OBJECT      MESSAGE
89s         Warning   FailedScheduling   pod/hello   0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

```

4\. Assign `disktype=ssd` to any one of the nodes and wait for the pod to be scheduled on that node.

```
[centos@ip-10-0-2-94 ~]$ kubectl label nodes ip-10-0-2-77.ap-southeast-2.compute.internal disktype=ssd
node/ip-10-0-2-77.ap-southeast-2.compute.internal labeled
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get events
LAST SEEN   TYPE      REASON             OBJECT      MESSAGE
4m1s        Warning   FailedScheduling   pod/hello   0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
4s          Normal    Scheduled          pod/hello   Successfully assigned myapp/hello to ip-10-0-2-77.ap-southeast-2.compute.internal
3s          Normal    Pulling            pod/hello   Pulling image "quay.io/mask365/scaling:latest"
0s          Normal    Pulled             pod/hello   Successfully pulled image "quay.io/mask365/scaling:latest" in 2.455209584s
0s          Normal    Created            pod/hello   Created container hello
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE     IP            NODE                                           NOMINATED NODE   READINESS GATES
hello   1/1     Running   0          4m53s   10.244.38.3   ip-10-0-2-77.ap-southeast-2.compute.internal   <none>           <none>
```

5\. Inspect the `webserver.yml` and `redis-cache.yml` files.

```
[centos@ip-10-0-2-94 scheduling]$ cat ~/kubernetes-101/labs/scheduling/webserver.yml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
  namespace: myapp
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 2
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx
```

```
[centos@ip-10-0-2-94 scheduling]$ cat ~/kubernetes-101/labs/scheduling/redis-cache.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: myapp
spec:
  selector:
    matchLabels:
      app: store
  replicas: 2
  template:
    metadata:
      labels:
        app: store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: redis-server
        image: redis:latest
```

6\. Create both the deployments using `kubectl create` command and observe how the pods are scheduled based on the `podAffinity` and `podAntiAffinity`

```
[centos@ip-10-0-2-94 scheduling]$ kubectl create -f  ~/kubernetes-101/labs/scheduling/webserver.yml 
deployment.apps/web-server created
```

```
[centos@ip-10-0-2-94 scheduling]$ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
hello                         1/1     Running   0          20m
web-server-7c96f6fb77-hx8zn   0/1     Pending   0          3s
web-server-7c96f6fb77-tvjq7   0/1     Pending   0          3s
```

webserver pod is in a pending state as there is not match for the affinity rule.

```
[centos@ip-10-0-2-94 scheduling]$ kubectl create -f  ~/kubernetes-101/labs/scheduling/redis-cache.yaml 
deployment.apps/redis-cache created
```

```
[centos@ip-10-0-2-94 scheduling]$ kubectl get pods -o wide
NAME                           READY   STATUS              RESTARTS   AGE   IP            NODE                                            NOMINATED NODE   READINESS GATES
hello                          1/1     Running             0          22m   10.244.38.3   ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
redis-cache-7f5555ffc7-ptqn4   0/1     ContainerCreating   0          2s    <none>        ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
redis-cache-7f5555ffc7-vzlgw   0/1     ContainerCreating   0          2s    <none>        ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
web-server-7c96f6fb77-hx8zn    0/1     Pending             0          80s   <none>        <none>                                          <none>           <none>
web-server-7c96f6fb77-tvjq7    0/1     ContainerCreating   0          80s   <none>        ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
```

7\. Observe how that pods are scheduled on the nodes

{% hint style="info" %}
If you have a single node, only 1 set of pods will be scheduled and the other set will be in pending state. This still demonstrates that requirement.&#x20;
{% endhint %}

```
[centos@ip-10-0-2-94 scheduling]$ kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE    IP             NODE                                            NOMINATED NODE   READINESS GATES
redis-cache-7f5555ffc7-ptqn4   1/1     Running   0          47s    10.244.38.4    ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
redis-cache-7f5555ffc7-vzlgw   1/1     Running   0          47s    10.244.45.67   ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
web-server-7c96f6fb77-hx8zn    1/1     Running   0          2m5s   10.244.38.5    ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
web-server-7c96f6fb77-tvjq7    1/1     Running   0          2m5s   10.244.45.68   ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
```

8\. Remove the `disktype` label from the node which we assigned in the previous step.

```
[centos@ip-10-0-2-94 scheduling]$ kubectl describe nodes ip-10-0-2-77.ap-southeast-2.compute.internal |grep -A4 Label
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    disktype=ssd
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-0-2-77.ap-southeast-2.compute.internal
```

```
[centos@ip-10-0-2-94 scheduling]$ kubectl label nodes ip-10-0-2-77.ap-southeast-2.compute.internal disktype-
node/ip-10-0-2-77.ap-southeast-2.compute.internal unlabeled
```

9\. Create a pod with `nodeAffinity`. This time we do not have a node with the required label but still the pod will be scheduled on a node and that is the use of

`preferredDuringSchedulingIgnoredDuringExecution`: The scheduler tries to find a node that meets the rule. If a matching node is not available, the scheduler still schedules the Pod.

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/scheduling/pod-nodeAffinity.yml 
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: myapp
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd          
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/scheduling/pod-nodeAffinity.yml
pod/nginx created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods nginx -o wide
NAME    READY   STATUS    RESTARTS   AGE     IP             NODE                                            NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          2m36s   10.244.45.69   ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
```

10\. CleanUp

```
[centos@ip-10-0-2-94 ~]$ kubectl delete all --all -n myapp
pod "hello" deleted
pod "nginx" deleted
pod "redis-cache-7f5555ffc7-p22tj" deleted
pod "redis-cache-7f5555ffc7-ptqn4" deleted
pod "redis-cache-7f5555ffc7-vzlgw" deleted
pod "redis-cache-7f5555ffc7-wwqfj" deleted
pod "web-server-7c96f6fb77-hx8zn" deleted
pod "web-server-7c96f6fb77-lpngc" deleted
pod "web-server-7c96f6fb77-tvjq7" deleted
pod "web-server-7c96f6fb77-txtd4" deleted
deployment.apps "redis-cache" deleted
deployment.apps "web-server" deleted
replicaset.apps "redis-cache-7f5555ffc7" deleted
replicaset.apps "web-server-7c96f6fb77" deleted
[centos@ip-10-0-2-94 ~]$ 
```

**Thats was it** :thumbsup:
