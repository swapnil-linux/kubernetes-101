# Lab: Network Policy

1. Lets start by creating a namespace and setting the context to it.

```
$ kubectl create ns network-policy
namespace/network-policy created

```

```
$ kubectl config set-context --current --namespace network-policy
Context "kubernetes-admin@kubernetes" modified.
 
```

2\. Create 2 pods and services using any image

```
$ kubectl run hello --image=quay.io/mask365/scaling --port 8080 
pod/hello created
```

```
$ kubectl run test --image=quay.io/mask365/scaling --port 8080 
pod/test created
```

```
$ kubectl expose pod hello
service/hello exposed
```

```
$ kubectl expose pod test
service/test exposed
```

```
$ kubectl get pods,svc 
NAME        READY   STATUS    RESTARTS   AGE
pod/hello   1/1     Running   0          51s
pod/test    1/1     Running   0          44s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/hello   ClusterIP   10.96.230.131   <none>        8080/TCP   10s
service/test    ClusterIP   10.96.8.175     <none>        8080/TCP   6s
[centos@ip-10-0-2-94 ~]$

```

3\. Use the `kubectl exec`  and `curl` commands to confirm that the test pod can access the hello service and vice versa.

```
$ kubectl exec hello -- curl -s http://test:8080
Scaling App V3: POD IP: 10.244.44.45
```

```
$ kubectl exec test -- curl -s http://hello:8080
Scaling App V3: POD IP: 10.244.44.44
```

4\. Create the `network-test` namespace and a `pod` and `service` named sample-app.

```
$ kubectl create ns network-test
namespace/network-test created
```

```
$ kubectl run sample-app --image=quay.io/mask365/scaling --port 8080 -n network-test
pod/sample-app created
```

```
$ kubectl expose pod sample-app -n network-test
service/sample-app exposed
```

5\. Verify that pods in a different namespace can access the hello and test pods in the network-policy namespace.

```
$ kubectl exec sample-app -n network-test  -- curl -s http://hello.network-policy.svc.cluster.local:8080
Scaling App V3: POD IP: 10.244.44.44
```

```
$ kubectl exec sample-app -n network-test  -- curl -s http://test.network-policy.svc.cluster.local:8080
Scaling App V3: POD IP: 10.244.44.45
```

6\. inspect the `deny-all.yml` file and create the networkpolicy with the `kubectl create` command.

```
$ cat ~/kubernetes-101/labs/network-policy/deny-all.yml 
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all
  namespace: network-policy
spec:
  podSelector: {}
```

```
$ kubectl create -f ~/kubernetes-101/labs/network-policy/deny-all.yml
networkpolicy.networking.k8s.io/deny-all created
```

7\. Verify that the test pod can no longer access the hello pod. Wait a few seconds, and then press `Ctrl+C` to exit the curl command that does not reply.

```
$ kubectl exec test -- curl -s http://hello:8080


^C
[centos@ip-10-0-2-94 ~]$ 
```

8\. Confirm that the sample-app pod can no longer access the hello and test pod. Wait a few seconds, and then press Ctrl+C to exit the curl command that does not reply.

```
$ kubectl exec sample-app -n network-test  -- curl -s http://hello.network-policy.svc.cluster.local:8080

^C
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl exec sample-app -n network-test  -- curl -s http://test.network-policy.svc.cluster.local:8080

^C
[centos@ip-10-0-2-94 ~]$ 
```

9\. inspect the allow-specific.yml and create the networkpolicy with the `kubectl create` command.

{% hint style="info" %}
_Ask your instructor to explain this_
{% endhint %}

```
$ cat ~/kubernetes-101/labs/network-policy/allow-specific.yml 
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-specific
  namespace: network-policy
spec:
  podSelector:
    matchLabels:
      run: hello
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: network-test
        podSelector:
          matchLabels:
            run: sample-app
      ports:
      - port: 8080
        protocol: TCP
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl create -f ~/kubernetes-101/labs/network-policy/allow-specific.yml
networkpolicy.networking.k8s.io/allow-specific created
```

10\. View the network policies in the network-policy namespace

```
$ kubectl get networkpolicies 
NAME             POD-SELECTOR   AGE
allow-specific   run=hello      28s
deny-all         <none>         6m9s
```

11\. Describe  the network-test namespace to check the default label

```
$ kubectl describe namespaces network-test 
Name:         network-test
Labels:       kubernetes.io/metadata.name=network-test
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

{% hint style="info" %}
The `allow-specific` network policy uses labels to match the name of a namespace. By default, namespaces gets `kubernetes.io/metadata.name` label but you can add your own using `kubectl label` command
{% endhint %}

12\. Verify access to the hello pod in the network-policy namespace

```
$ kubectl exec sample-app -n network-test  -- curl -s http://hello.network-policy.svc.cluster.local:8080
Scaling App V3: POD IP: 10.244.44.44
```

13\. Verify there is no access to the test pod. Wait a few seconds, and then press Ctrl+C to exit the curl command that does not reply.

```
$ kubectl exec sample-app -n network-test  -- curl -s http://test.network-policy.svc.cluster.local:8080
^C
```

14\. Clean Up.

```
$ kubectl delete all --all -n network-policy 
pod "hello" deleted
pod "test" deleted
service "hello" deleted
service "test" deleted
```

```
$ kubectl delete all --all -n network-test 
pod "sample-app" deleted
service "sample-app" deleted
```

```
$ kubectl config set-context --current --namespace myapp
Context "kubernetes-admin@kubernetes" modified.
```

**isn't it amazing** 😻&#x20;
