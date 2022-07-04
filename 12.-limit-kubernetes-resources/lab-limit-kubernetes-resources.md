# Lab: Limit Kubernetes Resources

1. Create a namespace `limit-test` and set context to it

```
[centos@ip-10-0-2-94 ~]$ kubectl create ns limit-test
namespace/limit-test created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl config set-context --current --namespace limit-test
Context "kubernetes-admin@kubernetes" modified.
```

2\. Create a deployment using `kubectl create deployment` command

```
[centos@ip-10-0-2-94 ~]$ kubectl create deployment stresstest  --image=quay.io/mask365/stresstest 
deployment.apps/stresstest created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -o wide
NAME                          READY   STATUS    RESTARTS   AGE     IP             NODE                                            NOMINATED NODE   READINESS GATES
stresstest-5857bb55fb-62wx5   1/1     Running   0          3m37s   10.244.45.76   ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>
[centos@ip-10-0-2-94 ~]$
```

3\. use top command to check the cpu utilization of `stress` application, its almost eating up all the available CPU

![](<../.gitbook/assets/Screen Shot 2022-07-04 at 12.42.38 pm.png>)

4\. Let's assign a cpu limit to the deployment.

```
[centos@ip-10-0-2-94 ~]$ kubectl set resources deployment stresstest  --limits=cpu=200m
deployment.apps/stresstest resource requirements updated
```

This will redeploy the pod and terminate the old pod.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -o wide
NAME                          READY   STATUS        RESTARTS   AGE     IP             NODE                                            NOMINATED NODE   READINESS GATES
stresstest-5577f69855-bhk2h   1/1     Running       0          34s     10.244.38.11   ip-10-0-2-77.ap-southeast-2.compute.internal    <none>           <none>
stresstest-5857bb55fb-62wx5   1/1     Terminating   0          8m23s   10.244.45.76   ip-10-0-2-184.ap-southeast-2.compute.internal   <none>           <none>

```

5\. Now, check the CPU utilization of the stress program again.

![](<../.gitbook/assets/Screen Shot 2022-07-04 at 12.47.01 pm.png>)

6\. Check the deployment yaml how the limit was assigned.

```
[centos@ip-10-0-2-94 ~]$ kubectl get deployments.apps stresstest -o yaml
apiVersion: apps/v1
kind: Deployment
...
...
    spec:
      containers:
      - image: quay.io/mask365/stresstest
        imagePullPolicy: Always
        name: stresstest
        resources:
          limits:
            cpu: 200m
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
```

7\. Create a `resourcequota` for namespace `limit-test`

```
[centos@ip-10-0-2-94 ~]$ kubectl create quota my-quota --hard=cpu=500m,memory=1Gi,pods=2,services=3 -n limit-test 
resourcequota/my-quota created
```

and check the current used limit

```
[centos@ip-10-0-2-94 ~]$ kubectl describe resourcequotas my-quota 
Name:       my-quota
Namespace:  limit-test
Resource    Used  Hard
--------    ----  ----
cpu         200m  500m
memory      0     1Gi
pods        1     2
services    0     3
[centos@ip-10-0-2-94 ~]$ 
```

8\. Lets create another deployment using the `scaling:v1` image, and check if the pod is deployed&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl create deployment scaling-1  --image=quay.io/mask365/scaling:v1 --port 8080  
deployment.apps/scaling-1 created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl expose deployment scaling-1 
service/scaling-1 exposed
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods
NAME                          READY   STATUS    RESTARTS        AGE
stresstest-5577f69855-bhk2h   1/1     Running   1 (9m37s ago)   19m
```

9\. Pod did not get deployed, to check the issue look at the events using `kubectl get events` command

```
[centos@ip-10-0-2-94 ~]$ kubectl get events --field-selector type=Warning
LAST SEEN   TYPE      REASON         OBJECT                            MESSAGE
5m58s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-mlbb2" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m58s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-hdd7r" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m58s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-9np9h" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m58s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-jxnxj" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m58s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-lcjqg" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m57s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-f2bg4" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m57s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-zfhml" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
5m57s       Warning   FailedCreate   replicaset/scaling-1-6549988799   Error creating: pods "scaling-1-6549988799-swrrv" is forbidden: failed quota: my-quota: must specify cpu for: scaling; memory for: scaling
```

10\. The message is quite clear, if a `resourcequota` is defined on a namespace, you need to specify resource `limit` on the pod as well. Lets do that.

```
[centos@ip-10-0-2-94 ~]$ kubectl set resources deployment scaling-1  --limits=cpu=100m,memory=128Mi
deployment.apps/scaling-1 resource requirements updated
```

you should notice the pod being scheduled

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -w
NAME                          READY   STATUS              RESTARTS        AGE
scaling-1-76ddf45bf5-7bkzm    0/1     ContainerCreating   0               9s
stresstest-5577f69855-bhk2h   1/1     Running             2 (3m55s ago)   24m
scaling-1-76ddf45bf5-7bkzm    1/1     Running             0               15s


```

11\. Check the limit usage again

```
[centos@ip-10-0-2-94 ~]$ kubectl describe resourcequotas my-quota 
Name:       my-quota
Namespace:  limit-test
Resource    Used   Hard
--------    ----   ----
cpu         300m   500m
memory      128Mi  1Gi
pods        2      2
services    1      3
[centos@ip-10-0-2-94 ~]$ 
```

12\. seems we have utilised all the pod limit, lets try scaling the deployment to 3 replicas

```
[centos@ip-10-0-2-94 ~]$ kubectl scale deployment scaling-1 --replicas=3
deployment.apps/scaling-1 scaled
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods
NAME                          READY   STATUS    RESTARTS        AGE
scaling-1-76ddf45bf5-7bkzm    1/1     Running   0               2m2s
stresstest-5577f69855-bhk2h   1/1     Running   2 (5m48s ago)   26m
```

13\. Did not get scaled, so lets check the warning again.

```
[centos@ip-10-0-2-94 ~]$ kubectl get events --field-selector type=Warning 
LAST SEEN   TYPE      REASON         OBJECT                            MESSAGE
...
...
35s         Warning   FailedCreate   replicaset/scaling-1-76ddf45bf5   (combined from similar events): Error creating: pods "scaling-1-76ddf45bf5-vfltr" is forbidden: exceeded quota: my-quota, requested: pods=1, used: pods=2, limited: pods=2
```

14\. Clean up

```
[centos@ip-10-0-2-94 ~]$ kubectl delete all --all -n limit-test 
pod "scaling-1-76ddf45bf5-7bkzm" deleted
pod "stresstest-5577f69855-bhk2h" deleted
service "scaling-1" deleted
deployment.apps "scaling-1" deleted
deployment.apps "stresstest" deleted
```

```
[centos@ip-10-0-2-94 ~]$ kubectl delete ns limit-test 
namespace "limit-test" deleted
```

```
[centos@ip-10-0-2-94 ~]$ kubectl config set-context --current --namespace default
Context "kubernetes-admin@kubernetes" modified.
```

_**The only limits that exist are the ones in your own mind.**_😉&#x20;
