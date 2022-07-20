# Lab: Kubernetes Probes

1. Set you current context to `myapp`

```
kubectl config set-context --current --namespace myapp
```

2\. Create a deployment using `quay.io/mask365/myslowapp` image

```
kubectl create deployment slowapp  --image=quay.io/mask365/myslowapp --port=8000 
```

expose the deployment as a NodePort service

```
kubectl expose deployment slowapp --type NodePort
```

3\. Check if the pod is up and try accessing the application

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
slowapp-69ff5f776c-mvg9w   1/1     Running   0          24s

```

find the service NodePort

```
$ kubectl get svc
NAME      TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
slowapp   NodePort   10.96.96.56   <none>        8000:32439/TCP   5s

```

```
$ curl http://localhost:32439/
curl: (7) Failed connect to localhost:32439; Connection refused

```

{% hint style="danger" %}
Pod shows that status as 1/1 but the app is still starting and so we see connection refused status
{% endhint %}

4\. Wait for a while and try again.

```
$ kubectl logs slowapp-69ff5f776c-mvg9w 
starting server..............................done
```

```
$ curl http://localhost:32439/
Welcome!!
```

5\. use `kubectl explain` to know more about readiness probe

```
$ kubectl explain deployment.spec.template.spec.containers.readinessProbe --recursive 
KIND:     Deployment
VERSION:  apps/v1

RESOURCE: readinessProbe <Object>

DESCRIPTION:
     Periodic probe of container service readiness. Container will be removed
     from service endpoints if the probe fails. Cannot be updated. More info:
     https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

     Probe describes a health check to be performed against a container to
     determine whether it is alive or ready to receive traffic.

FIELDS:
   exec	<Object>
      command	<[]string>
   failureThreshold	<integer>
   grpc	<Object>
      port	<integer>
      service	<string>
   httpGet	<Object>
      host	<string>
      httpHeaders	<[]Object>
         name	<string>
         value	<string>
      path	<string>
      port	<string>
      scheme	<string>
   initialDelaySeconds	<integer>
   periodSeconds	<integer>
   successThreshold	<integer>
   tcpSocket	<Object>
      host	<string>
      port	<string>
   terminationGracePeriodSeconds	<integer>
   timeoutSeconds	<integer>

```

6\. Lets add a readiness probe by editing the deployment&#x20;

```
kubectl edit deployments slowapp
```

add the last 4 lines in the below exibit below protocol

```
   spec:
      containers:
      - image: quay.io/mask365/myslowapp
        imagePullPolicy: Always
        name: myslowapp
        ports:
        - containerPort: 8000
          protocol: TCP
        readinessProbe:                          
          httpGet:
            path: /index.html
            port: 8000
```

7\. wait for the new pod to be deployed and notice that it takes a while for the pod to become ready

```
$ kubectl get pods -w
NAME                       READY   STATUS    RESTARTS   AGE
slowapp-68bcd99798-xft9z   0/1     Running   0          36s
slowapp-68bcd99798-xft9z   1/1     Running   0          41s
```

8\. Check for any warnings in the namespace eventlogs

```
$ kubectl get events --field-selector type=Warning
LAST SEEN   TYPE      REASON      OBJECT                         MESSAGE
3m8s        Warning   Unhealthy   pod/slowapp-68bcd99798-4fgmz   Readiness probe failed: Get "http://10.244.44.10:8000/index.html": dial tcp 10.244.44.10:8000: connect: connection refused
84s         Warning   Unhealthy   pod/slowapp-68bcd99798-xft9z   Readiness probe failed: Get "http://10.244.44.11:8000/index.html": dial tcp 10.244.44.11:8000: connect: connection refused

```

9\. scale the deployment to 3 replicas

```
kubectl scale deployment slowapp --replicas 3
```

10\. wait for the pods to show running status and check if the service is loadbalancing the requests

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
slowapp-68bcd99798-q9sj6   0/1     Running   0          22s
slowapp-68bcd99798-xft9z   1/1     Running   0          4m
slowapp-68bcd99798-zsvsf   0/1     Running   0          22s
```

even if the pods are running but the READY status is not 1/1, so the service will not load balance the requests

```
$ kubectl get endpoints slowapp 
NAME      ENDPOINTS          AGE
slowapp   10.244.44.11:8000  27m

```

11\. Wait for the pods to be fully ready and check the service endpoints again

```
$ kubectl get pods 
NAME                       READY   STATUS    RESTARTS   AGE
slowapp-68bcd99798-q9sj6   1/1     Running   0          5m39s
slowapp-68bcd99798-xft9z   1/1     Running   0          9m17s
slowapp-68bcd99798-zsvsf   1/1     Running   0          5m39s
```

```
$ kubectl get endpoints slowapp 
NAME      ENDPOINTS                                                 AGE
slowapp   10.244.147.97:8000,10.244.44.11:8000,10.244.67.207:8000   29m
```

12\. Delete the index.html file from any one of the pods, node the IP address of the pod that use for this task.

```
$ kubectl get pods -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP              NODE                                                  NOMINATED NODE   READINESS GATES
slowapp-68bcd99798-q9sj6   1/1     Running   0          8m    10.244.147.97   i-033814d334626dc61.ap-southeast-2.compute.internal   <none>           <none>
slowapp-68bcd99798-xft9z   1/1     Running   0          11m   10.244.44.11    i-0561c598e1387093f.ap-southeast-2.compute.internal   <none>           <none>
slowapp-68bcd99798-zsvsf   1/1     Running   0          8m    10.244.67.207   i-0923b8f25e214e3ed.ap-southeast-2.compute.internal   <none>           <none>

```

I chose the one with `10.244.44.11`

```
kubectl exec slowapp-68bcd99798-xft9z -- rm /opt/src/index.html
```

13\. Notice that in a while that pod will not be ready and removed from the endpoints

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
slowapp-68bcd99798-q9sj6   1/1     Running   0          9m42s
slowapp-68bcd99798-xft9z   0/1     Running   0          13m
slowapp-68bcd99798-zsvsf   1/1     Running   0          9m42s

```

```
$ kubectl get endpoints
NAME      ENDPOINTS                               AGE
slowapp   10.244.147.97:8000,10.244.67.207:8000   35m
```

14\. Thats it, Clean Up.

```
$ kubectl delete all --all -n myapp
pod "slowapp-68bcd99798-q9sj6" deleted
pod "slowapp-68bcd99798-xft9z" deleted
pod "slowapp-68bcd99798-zsvsf" deleted
service "slowapp" deleted
deployment.apps "slowapp" deleted

```
