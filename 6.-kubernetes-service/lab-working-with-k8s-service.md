# Lab: Working with K8S Service

1. Let's set our current context to namespace `myapp`

```
$ kubectl config set-context --current --namespace myapp
Context "kubernetes-admin@kubernetes" modified. 
```

2\. Create a deployment using `kubectl create deployment` command

```
$ kubectl create deployment scaling --image=quay.io/mask365/scaling:v3 --port 8080
deployment.apps/scaling created
```

3\. inspect `dual-stack-svc.yml` file

```
$ cat ~/kubernetes-101/labs/service/dual-stack-svc.yml 
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: scaling
  name: scaling
spec:
  ipFamilyPolicy: PreferDualStack   <<==== Assign IPv4 and IPv6 ClusterIPs
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: scaling
status:
  loadBalancer: {}
```

4\. Deploy it with the following command. This will only work if your cluster supports dual stack networking.

```
$ kubectl create -f ~/kubernetes-101/labs/service/dual-stack-svc.yml
service/scaling created
[centos@ip-10-0-2-94 ~]$ 
```

5\. List it and describe it with the following commands.

```
$ kubectl get svc
NAME      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
scaling   ClusterIP   10.96.77.182   <none>        8080/TCP   68s
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl describe svc scaling 
Name:              scaling
Namespace:         myapp
Labels:            app=scaling
Annotations:       <none>
Selector:          app=scaling
Type:              ClusterIP
IP Family Policy:  PreferDualStack
IP Families:       IPv4,IPv6                         <<=== IPv4 and IPv6 families
IP:                10.96.77.182
IPs:               10.96.77.182,2001:db8:42:1::a41d  <<=== IPv4 and IPv6 addresses
Port:              <unset>  8080/TCP
TargetPort:        8080/TCP
Endpoints:         10.244.44.10:8080
Session Affinity:  None
Events:            <none>
[centos@ip-10-0-2-94 ~]$  
```

6\. Create another service with type as `NodePort`

```
$ kubectl expose deployment scaling --name=scaling-single  --type NodePort
service/scaling-single exposed
```

7\. List it and describe it and notice the difference&#x20;

```
$ kubectl get svc
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
scaling          ClusterIP   10.96.202.48    <none>        8080/TCP         2m18s
scaling-single   NodePort    10.96.144.226   <none>        8080:31264/TCP   16m
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl describe svc scaling-single
Name:                     scaling-single
Namespace:                myapp
Labels:                   app=scaling
Annotations:              <none>
Selector:                 app=scaling
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.144.226
IPs:                      10.96.144.226
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31264/TCP
Endpoints:                10.244.44.4:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
[centos@ip-10-0-2-94 ~]$
```

8\. Every Service gets its own Endpoints object with the same name as the Service. This holds a list of all the Pods the Service matches and is dynamically updated as matching Pods come and go. You can see Endpoints, and the newer `EndpointSlices`, with the normal `kubectl` commands.

Notice how two EndpointSlice objects are created, one for the IPv4 mappings and the other for IPv6.

```
$ kubectl get endpointslices
NAME                   ADDRESSTYPE   PORTS   ENDPOINTS                            AGE
scaling-5ttsm          IPv6          8080    2001:db8:42:36:e895:4aab:2fbb:6c43   2m53s
scaling-dgc9v          IPv4          8080    10.244.44.4                          2m53s
scaling-single-2jv7p   IPv4          8080    10.244.44.4                          16m
[centos@ip-10-0-2-94 ~]$
```

9\. Create another deployment with `scaling:v2` image

```
$ kubectl create deployment scaling-v2 --image=quay.io/mask365/scaling:v2 --port 8080
deployment.apps/scaling-v2 created
[centos@ip-10-0-2-94 ~]$ 
```

10\. edit service `scaling` using `kubectl edit` command to change the selector and notice the difference in endpoints

```
$ kubectl edit svc scaling
service/scaling edited
[centos@ip-10-0-2-94 ~]$ 
```

replace the label on line 30 to `env: prod`

```
    protocol: TCP
    targetPort: 8080
  selector:
    env: prod                    <<=== replace old labels with this
  sessionAffinity: None
  type: ClusterIP
```

```
$ kubectl get endpointslices
NAME                   ADDRESSTYPE   PORTS     ENDPOINTS     AGE
scaling-5ttsm          IPv6          <unset>   <unset>       8m37s
scaling-dgc9v          IPv4          <unset>   <unset>       8m37s
scaling-single-2jv7p   IPv4          8080      10.244.44.4   22m
[centos@ip-10-0-2-94 ~]$ 
```

11\. Label both pods with the new labels so that `scaling` service points to both pods

```
$ kubectl get pods --show-labels 
NAME                          READY   STATUS    RESTARTS   AGE     LABELS
scaling-ffb48c86c-4x8vb       1/1     Running   0          6m50s   app=scaling,pod-template-hash=ffb48c86c
scaling-v2-75fd89d465-cxvh6   1/1     Running   0          6m50s   app=scaling-v2,pod-template-hash=75fd89d465
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl label `kubectl get pods -o name` env=prod
pod/scaling-ffb48c86c-4x8vb labeled
pod/scaling-v2-75fd89d465-cxvh6 labeled

```

{% hint style="info" %}
Pod names will differ then what should in the above output
{% endhint %}



12\. Notice the `endpointslices`  now point to both the pods

```
$ kubectl get endpointslices
NAME                   ADDRESSTYPE   PORTS   ENDPOINTS                                                               AGE
scaling-5ttsm          IPv6          8080    2001:db8:42:36:e895:4aab:2fbb:6c45,2001:db8:42:36:e895:4aab:2fbb:6c46   25m
scaling-dgc9v          IPv4          8080    10.244.44.6,10.244.44.7                                                 25m
scaling-single-2jv7p   IPv4          8080    10.244.44.6                                                             39m
[centos@ip-10-0-2-94 ~]$ 
```

13\. Clean up

```
$ kubectl delete all --all -n myapp
pod "scaling-ffb48c86c-4x8vb" deleted
pod "scaling-v2-75fd89d465-cxvh6" deleted
service "scaling" deleted
service "scaling-single" deleted
deployment.apps "scaling" deleted
deployment.apps "scaling-v2" deleted
[centos@ip-10-0-2-94 ~]$ 
```

**Theres more** :smile:
