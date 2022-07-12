# Lab: Injecting configuration data in Pod

1. Make sure we have `myapp` namespace and the current context is set to the same.

```
$ kubectl config get-contexts 
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin   myapp
```

2\. Try to deploy an ephemeral database server. This should fail because the MySQL image needs environment variables for its initial configuration.&#x20;

```
$ kubectl create deployment mysql --image=docker.io/mysql --port 3306 
deployment.apps/mysql created
```

```
$ kubectl expose deployment mysql 
service/mysql exposed
```

```
$ kubectl get pods
NAME                     READY   STATUS             RESTARTS      AGE
mysql-774b959dc4-bcrqn   0/1     CrashLoopBackOff   1 (16s ago)   24s
```

3\. inspect the reason for the failure. This image is expecting a few environment variables due to which the pod start is failing.

{% hint style="info" %}
As your instructor to dive deeper into the mysql image to show how these checks were implemented in the image
{% endhint %}

```
$ kubectl logs mysql-774b959dc4-bcrqn 
2022-07-02 22:51:29+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 8.0.29-1debian10 started.
2022-07-02 22:51:29+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
2022-07-02 22:51:29+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 8.0.29-1debian10 started.
2022-07-02 22:51:29+00:00 [ERROR] [Entrypoint]: Database is uninitialized and password option is not specified
    You need to specify one of the following:
    - MYSQL_ROOT_PASSWORD
    - MYSQL_ALLOW_EMPTY_PASSWORD
    - MYSQL_RANDOM_ROOT_PASSWORD
[centos@ip-10-0-2-94 ~]$ 
```

4\. Let's create another pod which is our frontend application

```
$ kubectl create deployment friends --image=quay.io/mask365/friends:latest --port 8080 
deployment.apps/friends created
```

```
$ kubectl expose deployment friends --type NodePort 
service/friends exposed
```

5\. This is what we have

```
$ kubectl get pods,service
NAME                           READY   STATUS             RESTARTS      AGE
pod/friends-578684d7d9-6b2nm   1/1     Running            0             2m57s
pod/mysql-774b959dc4-bcrqn     0/1     CrashLoopBackOff   6 (92s ago)   7m42s

NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/friends   NodePort    10.96.90.84     <none>        8080:30787/TCP   2m27s
service/mysql     ClusterIP   10.96.101.125   <none>        3306/TCP         7m28s

```

6\. Create a config map and secret with the required environment variables and connection information to access a MySQL database.

```
$ kubectl create configmap mycm1 --from-literal=MYSQL_DATABASE=friends --from-literal=DBHOST=mysql
configmap/mycm1 created
```

```
$ kubectl create secret generic mysec1 --from-literal=MYSQL_USER=user1 --from-literal=MYSQL_PASSWORD=da4456dfg112 --from-literal=MYSQL_ROOT_PASSWORD=bhy123o5848kasjaj
secret/mysec1 created
```

```
$ kubectl get configmaps mycm1 -o yaml
apiVersion: v1
data:
  DBHOST: mysql
  MYSQL_DATABASE: friends
kind: ConfigMap
metadata:
  creationTimestamp: "2022-07-02T23:01:12Z"
  name: mycm1
  namespace: myapp
  resourceVersion: "679035"
  uid: ebd5e911-ef31-41e2-83b7-fdc4dff4af28

```

```
$ kubectl get secrets mysec1 -o yaml
apiVersion: v1
data:
  MYSQL_PASSWORD: ZGE0NDU2ZGZnMTEy
  MYSQL_ROOT_PASSWORD: Ymh5MTIzbzU4NDhrYXNqYWo=
  MYSQL_USER: dXNlcjE=
kind: Secret
metadata:
  creationTimestamp: "2022-07-02T23:02:18Z"
  name: mysec1
  namespace: myapp
  resourceVersion: "679117"
  uid: 76eaacee-9171-4e98-b777-b3ded140b9ad
type: Opaque

```

7\. Inject the config map and secret into the mysql deployment and check if the pod startup succeeds&#x20;

```
$ kubectl set env deployment mysql --from configmap/mycm1
deployment.apps/mysql env updated
```

```
$ kubectl set env deployment mysql --from secret/mysec1
deployment.apps/mysql env updated
```

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
friends-578684d7d9-6b2nm   1/1     Running   0          12m
mysql-5589cbf9fc-w49bg     1/1     Running   0          22s
```

8\. Try accessing the friends application, it should still fail as we haven't injected the variables into the friends deployment.

```
$ curl http://localhost:30787
Connection failed: No such file or directory
```

So, let's do it.

```
$ kubectl set env deployment friends --from configmap/mycm1
deployment.apps/friends env updated
```

```
$ kubectl set env deployment friends --from secret/mysec1
deployment.apps/friends env updated
```

9\. Wait for a while for the pod to be redeployed and try accessing the application.

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
friends-6996f76d8b-n92kr   1/1     Running   0          57s
mysql-5589cbf9fc-w49bg     1/1     Running   0          3m13s
```

```
$ curl http://localhost:30787
<img width='500' src='friends.jpg' /><h1>List of Friends from 10.244.44.52</h1><br><br><p>0 results</p>[centos@ip-10-0-2-94 ~]$ 
```

10\. Inspect any one of the deployments to see how the environment variables are referenced

```
$ kubectl describe deployments mysql 
Name:                   mysql
Namespace:              myapp
...
...
    Environment:
      DBHOST:               <set to the key 'DBHOST' of config map 'mycm1'>            Optional: false
      MYSQL_DATABASE:       <set to the key 'MYSQL_DATABASE' of config map 'mycm1'>    Optional: false
      MYSQL_PASSWORD:       <set to the key 'MYSQL_PASSWORD' in secret 'mysec1'>       Optional: false
      MYSQL_ROOT_PASSWORD:  <set to the key 'MYSQL_ROOT_PASSWORD' in secret 'mysec1'>  Optional: false
      MYSQL_USER:           <set to the key 'MYSQL_USER' in secret 'mysec1'>           Optional: false
    Mounts:                 <none>
  Volumes:                  <none>
```

```
$ kubectl get deployments.apps friends -o yaml
apiVersion: apps/v1
kind: Deployment
...
...
    spec:
      containers:
      - env:
        - name: DBHOST
          valueFrom:
            configMapKeyRef:
              key: DBHOST
              name: mycm1
        - name: MYSQL_DATABASE
          valueFrom:
            configMapKeyRef:
              key: MYSQL_DATABASE
              name: mycm1
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              key: MYSQL_ROOT_PASSWORD
              name: mysec1
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              key: MYSQL_USER
              name: mysec1
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              key: MYSQL_PASSWORD
              name: mysec1
        image: quay.io/mask365/friends:latest
```

```
$ kubectl exec mysql-5589cbf9fc-w49bg -- env|grep MYSQL
MYSQL_USER=user1
MYSQL_DATABASE=friends
MYSQL_PASSWORD=da4456dfg112
MYSQL_ROOT_PASSWORD=bhy123o5848kasjaj
MYSQL_SERVICE_PORT=3306
MYSQL_PORT_3306_TCP_ADDR=10.96.101.125
MYSQL_PORT_3306_TCP_PROTO=tcp
MYSQL_PORT_3306_TCP=tcp://10.96.101.125:3306
MYSQL_SERVICE_HOST=10.96.101.125
MYSQL_PORT=tcp://10.96.101.125:3306
MYSQL_PORT_3306_TCP_PORT=3306
MYSQL_MAJOR=8.0
MYSQL_VERSION=8.0.29-1debian10
```

```
$ kubectl exec friends-6996f76d8b-n92kr -- env|grep MYSQL
MYSQL_USER=user1
MYSQL_PASSWORD=da4456dfg112
MYSQL_DATABASE=friends
MYSQL_ROOT_PASSWORD=bhy123o5848kasjaj
MYSQL_PORT_3306_TCP_PORT=3306
MYSQL_SERVICE_PORT=3306
MYSQL_SERVICE_HOST=10.96.101.125
MYSQL_PORT_3306_TCP_ADDR=10.96.101.125
MYSQL_PORT_3306_TCP=tcp://10.96.101.125:3306
MYSQL_PORT_3306_TCP_PROTO=tcp
MYSQL_PORT=tcp://10.96.101.125:3306
[centos@ip-10-0-2-94 ~]$ 
```

11\. Create another secret from a file `~/kubernetes-101/labs/secrets/secretfile.txt`

```
$ kubectl create secret generic mysec2 --from-file=kubernetes-101/labs/secrets/secretfile.txt
secret/mysec2 created
```

```
$ kubectl describe secrets mysec2
Name:         mysec2
Namespace:    myapp
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
secretfile.txt:  99 bytes
```

12\. Create a pod that references this secret as a volume

```
$ cat ~/kubernetes-101/labs/secrets/secret-pod.yml 
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
  labels:
    topic: secrets
spec:
  volumes:
  - name: secret-vol
    secret:
      secretName: mysec2
  containers:
  - name: secret-sssh
    image: quay.io/mask365/scaling:latest
    volumeMounts:
    - name: secret-vol
      mountPath: "/etc/sssh"

```

```
$ kubectl create -f ~/kubernetes-101/labs/secrets/secret-pod.yml
pod/secret-pod created
```

```
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
friends-6996f76d8b-n92kr   1/1     Running   0          29m
mysql-5589cbf9fc-w49bg     1/1     Running   0          31m
secret-pod                 1/1     Running   0          14s
```

13\. access the pod terminal and run a few commands which show how the secret is mounted as a volume.

```
kubectl exec -it secret-pod -- bash
```

```
bash-5.1# df -h /etc/sssh
Filesystem                Size      Used Available Use% Mounted on
tmpfs                     3.5G      4.0K      3.5G   0% /etc/sssh
```

```
bash-5.1# ls -la /etc/sssh/
total 0
drwxrwxrwt    3 root     root           100 Jul  2 23:38 .
drwxr-xr-x    1 root     root            37 Jul  2 23:38 ..
drwxr-xr-x    2 root     root            60 Jul  2 23:38 ..2022_07_02_23_38_46.2682275478
lrwxrwxrwx    1 root     root            32 Jul  2 23:38 ..data -> ..2022_07_02_23_38_46.2682275478
lrwxrwxrwx    1 root     root            21 Jul  2 23:38 secretfile.txt -> ..data/secretfile.txt
bash-5.1# 
```

```
bash-5.1# cat /etc/sssh/secretfile.txt 
U: Have you heard the joke about the spy?
Me: No, tell me.
U: Sorry, I can’t. It’s top secret.
bash-5.1# 

```

14\. Modify the content of the secret using `kubectl edit` command and wait for atleast 60seconds for the changes to reflect

```
kubectl edit secrets mysec2
```

```
apiVersion: v1
data:
  secretfile.txt: VTogSGF2ZSB5b3UgaGVhcmQgdGhlIGpva2UgYWJvdXQgdGhlIHNweT8KTWU6IE5vLCB0ZWxsIG1lLgpVOiBTb3JyeSwgSSBjYW7igJl0LiBJdOKAmXMgdG9wIHNlY3JldC4K
stringData:                                        <<=== Add this 2 lines
  anothersecret.txt: Another top secret file       <<=== Add this 2 lines
kind: Secret

```

```
$ kubectl exec secret-pod -- ls /etc/sssh
anothersecret.txt
secretfile.txt
```

```
$ kubectl exec secret-pod -- cat /etc/sssh/anothersecret.txt
Another top secret file
```

{% hint style="info" %}
Changes to volumes are synced within a minute whereas changes to the environment variable require the pod to be restarted.
{% endhint %}

15\. Clean Up

```
$ kubectl delete all --all -n myapp
pod "friends-6996f76d8b-n92kr" deleted
pod "mysql-5589cbf9fc-w49bg" deleted
pod "secret-pod" deleted
service "friends" deleted
service "mysql" deleted
deployment.apps "friends" deleted
deployment.apps "mysql" deleted
[centos@ip-10-0-2-94 ~]$ 
```

{% hint style="info" %}
`delete all` does not delete any persistent resources like configmaps, secrets and persistent volume claim. So we have to delete it manually.
{% endhint %}

```
$ kubectl delete configmaps --all
configmap "kube-root-ca.crt" deleted
configmap "mycm1" deleted
```

```
$ kubectl delete secrets --all
secret "mysec1" deleted
secret "mysec2" deleted
```

**It is no longer a secret** 🤫&#x20;
