# Lab: Managing Deployments

1. Let's set our current context to namespace `myapp`

```
$ kubectl config set-context --current --namespace myapp
Context "kubernetes-admin@kubernetes" modified. 
```

```
$ kubectl config get-contexts 
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   myapp
[centos@ip-10-0-2-94 ~]$
```

2\. Create a yaml file for deployment named scaling using `quay.io/mask365/scaling:latest` image using the below command.&#x20;

```
kubectl create deployment scaling --image=quay.io/mask365/scaling:v1 \ 
--port 8080 --dry-run=client --output yaml | \ 
tee /tmp/scaling-deploy.yml
```

3\. Edit the yaml to change the `replicas` to `3` and add label as `env=prod`for both deployment and pods specs.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: scaling
    env: prod
  name: scaling
spec:
  replicas: 3
  selector:
    matchLabels:
      app: scaling
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: scaling
        env: prod
    spec:
      containers:
      - image: quay.io/mask365/scaling:v1
        name: scaling
        ports:
        - containerPort: 8080
        resources: {}
status: {}
```

{% hint style="info" %}
Compare your file with the one in labs folder

`[centos@ip-10-0-2-94 ~]$ diff /tmp/scaling-deploy.yml ~/kubernetes-101/labs/deployments/scaling-deploy.yml`&#x20;

`6a7`

`>     env: prod`

`9c10`

`<   replicas: 2`

`---`

`>   replicas: 3`

`18a20`

`>         env: prod`
{% endhint %}

4\. Use `kubectl create` to deploy it on the cluster.

```
$ kubectl create -f /tmp/scaling-deploy.yml 
deployment.apps/scaling created
[centos@ip-10-0-2-94 ~]$ 
```

5\. Use the  `kubectl get` and `kubectl describe` commands to see details of Deployments and ReplicaSets.

```
$ kubectl get deploy -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
scaling   3/3     3            3           27s   scaling      quay.io/mask365/scaling:v1   app=scaling
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl describe deploy scaling
Name:                   scaling
Namespace:              myapp
CreationTimestamp:      Fri, 24 Jun 2022 02:21:24 +0000
Labels:                 app=scaling
                        env=prod
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=scaling
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=scaling
           env=prod
....
....
```

6\. As mentioned earlier, Deployments automatically create associated ReplicaSets. Verify this with the following command.

```
$ kubectl get rs -o wide
NAME                 DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                    SELECTOR
scaling-5c8b86bcc6   3         3         3       3m55s   scaling      quay.io/mask365/scaling:v1   app=scaling,pod-template-hash=5c8b86bcc6
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl get pods 
NAME                       READY   STATUS    RESTARTS   AGE
scaling-5cf66b5fcc-7t497   1/1     Running   0          2m6s
scaling-5cf66b5fcc-lqhcw   1/1     Running   0          2m6s
scaling-5cf66b5fcc-wzw4f   1/1     Running   0          2m6s
[centos@ip-10-0-2-94 ~]$ 
```

7\. Create NodePort service and access the application

```
$ kubectl expose deployment scaling --type=NodePort 
service/scaling exposed
```

```
$ kubectl get svc -o wide
NAME      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE   SELECTOR
scaling   NodePort   10.103.216.116   <none>        8080:30298/TCP   72s   app=scaling
```

{% hint style="info" %}
_Note the service node port, you will need this to access the application_
{% endhint %}

```
$ curl http://localhost:30298
Scaling App V1: POD IP: 10.85.0.30
```

8\. Lets write a simple loop to access the application multiple times and notice that it is load balances between available pods.

```
while sleep 1
do 
curl http://localhost:`kubectl get svc -o yaml|grep nodePort|awk '{print $3}'`
done
```

{% hint style="info" %}
Press Ctrl+C to terminate
{% endhint %}

```
$ while sleep 1; do curl http://localhost:`kubectl get svc -o yaml|grep nodePort|awk '{print $3}'`; done
Scaling App V1: POD IP: 10.85.0.31
Scaling App V1: POD IP: 10.85.0.32
Scaling App V1: POD IP: 10.85.0.30
Scaling App V1: POD IP: 10.85.0.30
Scaling App V1: POD IP: 10.85.0.31
Scaling App V1: POD IP: 10.85.0.32^C
[centos@ip-10-0-2-94 ~]$ 
```

9\. Run the following imperative commands to scale up to 5 and verify the operation.

```
$ kubectl scale deployment scaling --replicas=5
deployment.apps/scaling scaled
[centos@ip-10-0-2-94 ~]$
```

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
scaling-5cf66b5fcc-7dp8n   1/1     Running   0          37s
scaling-5cf66b5fcc-7t497   1/1     Running   0          22m
scaling-5cf66b5fcc-c8mxj   1/1     Running   0          37s
scaling-5cf66b5fcc-lqhcw   1/1     Running   0          22m
scaling-5cf66b5fcc-wzw4f   1/1     Running   0          22m
[centos@ip-10-0-2-94 ~]$ 
```

10\. Change the container image line in the Pod template section to use the `v2` image. To edit the deployment use `kubectl edit` command.\


```
$ kubectl edit deployments.apps scaling 
deployment.apps/scaling edited
[centos@ip-10-0-2-94 ~]$ 
```



```
    spec:
      containers:
      - image: quay.io/mask365/scaling:v2
        imagePullPolicy: IfNotPresent
        name: scaling
```

11\. You can monitor the progress with `kubectl rollout status.`

```
$ kubectl rollout status deployment scaling                                                              
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 4 of 5 updated replicas are available...
deployment "scaling" successfully rolled out
[centos@ip-10-0-2-94 ~]$ 

```

12\. The following commands show the two `ReplicaSet` objects. The second command shows the config of the old one and that it still references the old image version.&#x20;

```
$ kubectl get rs
NAME                 DESIRED   CURRENT   READY   AGE
scaling-5cf66b5fcc   0         0         0       33m
scaling-666d89f5b7   5         5         5       110s
```

```
$ kubectl describe rs scaling-5cf66b5fcc
Name:           scaling-5cf66b5fcc
Namespace:      myapp
Selector:       app=scaling,pod-template-hash=5cf66b5fcc
...
...
Pod Template:
  Labels:  app=scaling
           env=prod
           pod-template-hash=5cf66b5fcc
  Containers:
   scaling:
    Image:        quay.io/mask365/scaling:v1
    Port:         8080/TCP
```

13\. And we have application v2 up and running

```
$ curl http://localhost:30298
Scaling App V3: POD IP: 10.85.0.42
```

14\. The following command uses `kubectl rollout` to revert the application to `revision 1`.

```
$ kubectl rollout undo deployment scaling --to-revision=1 ; kubectl rollout status deployment scaling

deployment.apps/scaling rolled back
Waiting for deployment "scaling" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "scaling" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "scaling" rollout to finish: 4 of 5 updated replicas are available...
deployment "scaling" successfully rolled out
[centos@ip-10-0-2-94 ~]$ 
```

15\. Notice the change in replicaset and try accessing the application

```
$ kubectl get rs
NAME                 DESIRED   CURRENT   READY   AGE
scaling-5cf66b5fcc   5         5         5       41m
scaling-666d89f5b7   0         0         0       10m
```

```
$ curl http://localhost:30298
Scaling App V1: POD IP: 10.85.0.49
```

16\. Cleanup&#x20;

```
$ kubectl delete all --all -n myapp
pod "scaling-5cf66b5fcc-64lxj" deleted
pod "scaling-5cf66b5fcc-b9sgb" deleted
pod "scaling-5cf66b5fcc-jv2t9" deleted
pod "scaling-5cf66b5fcc-w44w6" deleted
pod "scaling-5cf66b5fcc-xqp4c" deleted
service "scaling" deleted
deployment.apps "scaling" deleted
replicaset.apps "scaling-5cf66b5fcc" deleted
[centos@ip-10-0-2-94 ~]$ 
```

_**That was amazing**_** 🤩**&#x20;
