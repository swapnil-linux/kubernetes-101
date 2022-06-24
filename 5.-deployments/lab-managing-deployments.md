# Lab: Managing Deployments

1. Let's set our current context to namespace `myapp`

```
[centos@ip-10-0-2-94 ~]$ kubectl config set-context --current --namespace myapp
Context "kubernetes-admin@kubernetes" modified. 
```

```
[centos@ip-10-0-2-94 ~]$ kubectl config get-contexts 
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   myapp
[centos@ip-10-0-2-94 ~]$
```

2\. Create a yaml file for deployment named scaling using `quay.io/mask365/scaling:latest` image using the below command.&#x20;

```
kubectl create deployment scaling --image=quay.io/mask365/scaling --port 8080 --dry-run=client --output yaml | tee /tmp/scaling-deploy.yml
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
      - image: quay.io/mask365/scaling
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
[centos@ip-10-0-2-94 ~]$ kubectl create -f /tmp/scaling-deploy.yml 
deployment.apps/scaling created
[centos@ip-10-0-2-94 ~]$ 
```

5\. Use the  `kubectl get` and `kubectl describe` commands to see details of Deployments and ReplicaSets.

```
[centos@ip-10-0-2-94 ~]$ kubectl get deploy -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
scaling   3/3     3            3           27s   scaling      quay.io/mask365/scaling   app=scaling
[centos@ip-10-0-2-94 ~]$ 
```

```
[centos@ip-10-0-2-94 ~]$ kubectl describe deploy scaling
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
[centos@ip-10-0-2-94 ~]$ kubectl get rs -o wide
NAME                 DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                    SELECTOR
scaling-5c8b86bcc6   3         3         3       3m55s   scaling      quay.io/mask365/scaling   app=scaling,pod-template-hash=5c8b86bcc6
[centos@ip-10-0-2-94 ~]$ 
```
