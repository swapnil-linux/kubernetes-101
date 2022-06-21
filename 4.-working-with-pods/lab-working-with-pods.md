# Lab: Working with Pods

Pre-requisite:

* Kubernetes up and running
* Clone git repo in home directory

```
cd ~/
git clone https://github.com/swapnil-linux/kubernetes-101
```

1. Create a namespace as `myapp` which will be used for this exercise.

```
kubectl create namespace myapp
```

2\. List any existing Pods in myapp&#x20;

```
kubectl get pods -n myapp
```

**OUTPUT:**

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp
No resources found in myapp namespace.
[centos@ip-10-0-2-94 ~]$ 
```

3\. You’ll be using the following Pod manifest to create pod in myapp namespace. It’s available in the book’s GitHub repo under the labs/pods folder called pod.yml

```
kubectl create -f kubernetes-101/labs/pods/pods.yml -n myapp
```

**OUTPUT**:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f kubernetes-101/labs/pods/pods.yml -n myapp 
pod/hello-pod created
[centos@ip-10-0-2-94 ~]$ 
```

4\. Run a `kubectl get pods` to check the status.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp
NAME        READY   STATUS    RESTARTS   AGE
hello-pod   1/1     Running   0          26s
[centos@ip-10-0-2-94 ~]$
```

5\. You can add a couple of flags that give you more information:

* \-o wide gives a few more columns but is still a single line of output
* \-o yaml takes things to the next level, returning a full copy of the Pod from the cluster store.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP          NODE                                           NOMINATED NODE   READINESS GATES
hello-pod   1/1     Running   0          7m17s   10.85.0.6   ip-10-0-2-94.ap-southeast-2.compute.internal   <none>           <none>
[centos@ip-10-0-2-94 ~]$
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp -o yaml | head -20
apiVersion: v1
items:
- apiVersion: v1
  kind: Pod
  metadata:
    creationTimestamp: "2022-06-21T03:46:14Z"
    labels:
      env: prod
      version: v1
    name: hello-pod
    namespace: myapp
    resourceVersion: "97177"
    uid: 1d5374b4-52f5-4e59-8508-da9028dedeca
  spec:
    containers:
    - image: docker.io/nginx:latest
      imagePullPolicy: Always
      name: hello
      ports:
      - containerPort: 80
```

6\. Use  `kubectl describe` for further introspection. This provides a nicely formatted multi-line overview of an object. It even includes important object lifecycle events.

```
[centos@ip-10-0-2-94 ~]$ kubectl describe pod hello-pod -n myapp
Name:         hello-pod
Namespace:    myapp
Priority:     0
Node:         ip-10-0-2-94.ap-southeast-2.compute.internal/10.0.2.94
Start Time:   Tue, 21 Jun 2022 03:46:14 +0000
Labels:       env=prod
              version=v1
Annotations:  <none>
Status:       Running
IP:           10.85.0.6
IPs:
  IP:  10.85.0.6
  IP:  1100:200::6
Containers:
  hello:
    Container ID:   cri-o://7f29a40a00fbc1ab90d516f133f067d24da93b62367ed979981ca9321da451c9
    Image:          docker.io/nginx:latest
    Image ID:       docker.io/library/nginx@sha256:25dedae0aceb6b4fe5837a0acbacc6580453717f126a095aa05a3c6fcea14dd4
    Port:           80/TCP
    Host Port:      0/TCP
....
....
....    
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  18m   default-scheduler  Successfully assigned myapp/hello-pod to ip-10-0-2-94.ap-southeast-2.compute.internal
  Normal  Pulling    18m   kubelet            Pulling image "docker.io/nginx:latest"
  Normal  Pulled     18m   kubelet            Successfully pulled image "docker.io/nginx:latest" in 3.268620952s
  Normal  Created    18m   kubelet            Created container hello
  Normal  Started    18m   kubelet            Started container hello
[centos@ip-10-0-2-94 ~]$ 
```

7\. Lets create a multi-container pod using the following YAML which defines a multi-container Pod with an init container and main app container.&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f kubernetes-101/labs/pods/initpod.yml -n myapp
pod/initpod-demo created
[centos@ip-10-0-2-94 ~]$ 
```

8\. Run a `kubectl get pods` with the `--watch` flag.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp -w
NAME           READY   STATUS     RESTARTS   AGE
hello-pod      1/1     Running    0          49m
initpod-demo   0/1     Init:0/1   0          10s
```

{% hint style="info" %}
The Init:0/1 status tells you that zero out of one init containers has completed successfully. The Pod will remain in this phase until a Service called “webapp” is created.
{% endhint %}



9\. Visit logs of `init-con` container in pod `initpod-demo`

```
[centos@ip-10-0-2-94 ~]$ kubectl logs -n myapp initpod-demo -c init-con|more
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find webapp.myapp.svc.cluster.local: NXDOMAIN

*** Can't find webapp.svc.cluster.local: No answer
*** Can't find webapp.cluster.local: No answer
*** Can't find webapp.ap-southeast-2.compute.internal: No answer
*** Can't find webapp.myapp.svc.cluster.local: No answer
*** Can't find webapp.svc.cluster.local: No answer
*** Can't find webapp.cluster.local: No answer
*** Can't find webapp.ap-southeast-2.compute.internal: No answer
```

10\. Press Ctrl-c to quit the current watch session and then create the Service and watch the Pod status change.

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f kubernetes-101/labs/pods/initsvc.yml -n myapp 
service/webapp created
[centos@ip-10-0-2-94 ~]$ 
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp -w
NAME           READY   STATUS     RESTARTS   AGE
hello-pod      1/1     Running    0          54m
initpod-demo   0/1     Init:0/1   0          5m16s
initpod-demo   0/1     PodInitializing   0          5m18s
initpod-demo   1/1     Running           0          5m24s
```

11\. Revisit the logs of init-con container

```
[centos@ip-10-0-2-94 ~]$ kubectl logs -n myapp initpod-demo -c init-con | tail -2

Service found!
[centos@ip-10-0-2-94 ~]$ 
```

{% hint style="info" %}
As soon as the Service appears, the init container successfully completes and the main application container starts.
{% endhint %}

12\. Create another multi-container pod using sidecar.yaml  and check the status

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f kubernetes-101/labs/pods/sidecar.yml -n myapp
pod/git-sync created
service/svc-sidecar created
[centos@ip-10-0-2-94 ~]$ 
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n myapp
NAME           READY   STATUS    RESTARTS   AGE
git-sync       2/2     Running   0          7m41s
hello-pod      1/1     Running   0          78m
initpod-demo   1/1     Running   0          28m
[centos@ip-10-0-2-94 ~]$ 
```

13\. As soon as the Pod enters the running state, check the synced files in both containers.&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -n myapp git-sync -c webapp -- ls /usr/share/nginx/html/
README.md
SECURITY.md
abc.html
index.php
test.php
```

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -n myapp git-sync -c syncapp -- ls /tmp/git/html/
README.md
SECURITY.md
abc.html
index.php
test.php
[centos@ip-10-0-2-94 ~]$ 
```

14\. run `kubectl get svc` to get the connection details and access the app

```
[centos@ip-10-0-2-94 ~]$ kubectl get svc -n myapp -o wide
NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE     SELECTOR
svc-sidecar   NodePort    10.103.60.32   <none>        80:30001/TCP   9m42s   app=sidecar
webapp        ClusterIP   10.99.224.33   <none>        80/TCP         25m     app=initializer
[centos@ip-10-0-2-94 ~]$ 
```

```
[centos@ip-10-0-2-94 ~]$ curl http://localhost:30001/abc.html
Hiiii
[centos@ip-10-0-2-94 ~]$ 
```

15\. Monitor the logs of syncapp pod in follow mode

{% hint style="info" %}
Once you are done till this step, ask your instructor to make changes to the abc.html and check if the changes are reflected immediately.
{% endhint %}

```
[centos@ip-10-0-2-94 ~]$ kubectl logs -n myapp git-sync -f -c syncapp
....
....
....
I0621 05:09:05.793463       9 main.go:676]  "level"=0 "msg"="update required"  "local"="b2b67e6b5113361e76e5f2d6b35a3275118e1077" "remote"="d7aa02c8cf09d15652ef4a9f868be2971d48113d" "rev"="HEAD"
I0621 05:09:05.793974       9 main.go:480]  "level"=0 "msg"="syncing git"  "hash"="d7aa02c8cf09d15652ef4a9f868be2971d48113d" "rev"="HEAD"
I0621 05:09:06.646345       9 main.go:501]  "level"=0 "msg"="adding worktree"  "branch"="origin/master" "path"="/tmp/git/rev-d7aa02c8cf09d15652ef4a9f868be2971d48113d"
I0621 05:09:06.650190       9 main.go:524]  "level"=0 "msg"="reset worktree to hash"  "hash"="d7aa02c8cf09d15652ef4a9f868be2971d48113d" "path"="/tmp/git/rev-d7aa02c8cf09d15652ef4a9f868be2971d48113d"
I0621 05:09:06.650213       9 main.go:528]  "level"=0 "msg"="updating submodules"  
```

```
[centos@ip-10-0-2-94 ~]$ curl http://localhost:30001/abc.html
Hiiii Again
[centos@ip-10-0-2-94 ~]$ 
```

16\. Find the container id of both containers in git-sync pod

```
[centos@ip-10-0-2-94 ~]$ sudo crictl ps |grep git-sync 
8db176b3e08c5       k8s.gcr.io/git-sync@sha256:3c1721915d0499c44068d13791b24137afbe03e19a763dc318a4ca689950ee2f       24 minutes ago      Running             syncapp                   0                   0957f721e636b       git-sync
b6b1def7b2eae       docker.io/library/nginx@sha256:25dedae0aceb6b4fe5837a0acbacc6580453717f126a095aa05a3c6fcea14dd4   25 minutes ago      Running             webapp                    0                   0957f721e636b       git-sync
[centos@ip-10-0-2-94 ~]$ 
```

17\. Inspect both containers to find the process id

```
[centos@ip-10-0-2-94 ~]$ sudo crictl inspect 8db176b3e08c5 |grep pid
    "pid": 4465,
          "pids": {
            "type": "pid"
```

```
[centos@ip-10-0-2-94 ~]$ sudo crictl inspect b6b1def7b2eae |grep pid
    "pid": 4374,
          "pids": {
            "type": "pid"
[centos@ip-10-0-2-94 ~]$ 
```

18\. Check the namespace id of both processes and find the match.

```
[centos@ip-10-0-2-94 ~]$ sudo ls -l /proc/4465/ns 
total 0
lrwxrwxrwx. 1 65533 65533 0 Jun 21 04:59 ipc -> ipc:[4026532500]
lrwxrwxrwx. 1 65533 65533 0 Jun 21 04:59 mnt -> mnt:[4026532580]
lrwxrwxrwx. 1 65533 65533 0 Jun 21 04:59 net -> net:[4026532502]
lrwxrwxrwx. 1 65533 65533 0 Jun 21 04:59 pid -> pid:[4026532581]
lrwxrwxrwx. 1 65533 65533 0 Jun 21 05:24 user -> user:[4026531837]
lrwxrwxrwx. 1 65533 65533 0 Jun 21 04:59 uts -> uts:[4026532499]
```

```
[centos@ip-10-0-2-94 ~]$ sudo ls -l /proc/4374/ns 
total 0
lrwxrwxrwx. 1 root root 0 Jun 21 05:00 ipc -> ipc:[4026532500]
lrwxrwxrwx. 1 root root 0 Jun 21 05:00 mnt -> mnt:[4026532578]
lrwxrwxrwx. 1 root root 0 Jun 21 05:00 net -> net:[4026532502]
lrwxrwxrwx. 1 root root 0 Jun 21 05:00 pid -> pid:[4026532579]
lrwxrwxrwx. 1 root root 0 Jun 21 05:25 user -> user:[4026531837]
lrwxrwxrwx. 1 root root 0 Jun 21 05:00 uts -> uts:[4026532499]
[centos@ip-10-0-2-94 ~]$ 
```

19\. Cleanup

```
[centos@ip-10-0-2-94 ~]$ kubectl delete all --all -n myapp
pod "git-sync" deleted
pod "hello-pod" deleted
pod "initpod-demo" deleted
service "svc-sidecar" deleted
service "webapp" deleted
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get all -n myapp
No resources found in myapp namespace.
[centos@ip-10-0-2-94 ~]$ 
```



_**You did good today 😊**_&#x20;
