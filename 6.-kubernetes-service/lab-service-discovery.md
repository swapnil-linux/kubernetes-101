# Lab: Service Discovery

1. Inspect the `friends-app.yaml` in your labs folder. This defines 2 namespaces, 2 deployments and 2 services. Also node the environment variables defined in both deployments.

```
$ cat ~/kubernetes-101/labs/service/friends-app.yaml 
apiVersion: v1
kind: Namespace
metadata:
  name: backend
---
apiVersion: v1
kind: Namespace
metadata:
  name: webapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mysql
  name: mysql
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: mysql
    spec:
      containers:
      - image: docker.io/mysql
        name: mysql
        env:
        - name: MYSQL_USER
          value: user1
        - name: MYSQL_PASSWORD
          value: pass1234
        - name: MYSQL_DATABASE
          value: friends
        - name: MYSQL_ROOT_PASSWORD
          value: notsostrongpass
        ports:
        - containerPort: 3306
        resources: {}
---  
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: friends
  name: friends
  namespace: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: friends
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: friends
    spec:
      containers:
      - image: quay.io/mask365/friends:latest
        name: friends
        env:
        - name: MYSQL_USER
          value: user1
        - name: MYSQL_PASSWORD
          value: pass1234
        - name: MYSQL_DATABASE
          value: friends        
        ports:
        - containerPort: 8080
        resources: {}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mysql
  name: mysql
  namespace: backend
spec:
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
  selector:
    app: mysql
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: friends
  name: friends
  namespace: webapp
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
    nodePort: 30200
  selector:
    app: friends
  type: NodePort
---
apiVersion: v1
kind: Pod
metadata:
  name: jump
  namespace: webapp
spec:
  terminationGracePeriodSeconds: 5
  containers:
  - image: alpine
    name: jump
    tty: true
    stdin: true  
[centos@ip-10-0-2-94 ~]$
```

2\. Deploy the configuration to your cluster.

```
$ kubectl create -f  ~/kubernetes-101/labs/service/friends-app.yaml 
namespace/backend created
namespace/webapp created
deployment.apps/mysql created
deployment.apps/friends created
service/mysql created
service/friends created
pod/jump created
[centos@ip-10-0-2-94 ~]$ 
```

3\. Check it was correctly applied.

```
$ kubectl get all -n webapp

NAME                           READY   STATUS    RESTARTS   AGE
pod/friends-56bffccd77-trtw7   1/1     Running   0          55s
pod/jump                       1/1     Running   0          55s

NAME              TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/friends   NodePort   10.96.119.98   <none>        8080:30200/TCP   55s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/friends   1/1     1            1           55s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/friends-56bffccd77   1         1         1       55s
[centos@ip-10-0-2-94 ~]$ 
```

```
$ kubectl get all -n backend

NAME                         READY   STATUS              RESTARTS   AGE
pod/mysql-67865878ff-8v7vl   0/1     ContainerCreating   0          36s

NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/mysql   ClusterIP   10.96.233.28   <none>        3306/TCP   36s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mysql   0/1     1            0           36s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/mysql-67865878ff   1         1         0       36s
```

4\. Connect to the `jump` Pod.

```
$ kubectl -n webapp exec -it jump -- sh
/ # 
```

Your terminal prompt will change to indicate you are attached to the jump Pod.

5\. Inspect the contents of the `/etc/resolv.conf` file and verify the search domains listed includes the `myapp` Namespace.

```
/ # cat /etc/resolv.conf 
search webapp.svc.cluster.local svc.cluster.local cluster.local ap-southeast-2.compute.internal
nameserver 10.96.0.10
options ndots:5
/ #  
```

6\. Try resolving friends service using `nslookup` command

```
/ # nslookup friends
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	friends.webapp.svc.cluster.local
Address: 10.96.184.57
```

try resolving mysql service which is in backend namespace

```
/ # nslookup mysql
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find mysql.svc.cluster.local: NXDOMAIN

** server can't find mysql.webapp.svc.cluster.local: NXDOMAIN

** server can't find mysql.svc.cluster.local: NXDOMAIN

** server can't find mysql.cluster.local: NXDOMAIN

** server can't find mysql.webapp.svc.cluster.local: NXDOMAIN

** server can't find mysql.cluster.local: NXDOMAIN

** server can't find mysql.ap-southeast-2.compute.internal: NXDOMAIN

** server can't find mysql.ap-southeast-2.compute.internal: NXDOMAIN

/ # 
```

7\. Try resolving `mysql` service again, this time using the FQDN

```
/ # nslookup mysql.backend.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	mysql.backend.svc.cluster.local
Address: 10.96.114.11
```

8\. exit the jump pod and copy `friends.sql` file in `jump` pod. We will use this to create a table in database and inject some records.

```
kubectl cp -n webapp ~/kubernetes-101/labs/service/friends.sql jump:/tmp/
```

access the `jump` pod

```
kubectl -n webapp exec -it jump -- sh
```

install mysql-client

```
apk add mysql-client mariadb-connector-c
```

connect to database and create the table

```
mysql -uuser1 -ppass1234 -hmysql.backend.svc.cluster.local friends < /tmp/friends.sql
```

9\. Lets try to access our application, this time using a browser. Use `http://<nodeip>:30200`

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 2.25.25 pm.png>)

We see this error because the webapp does not have the DBHOST variable set.&#x20;

10\. Lets add another environment variable and try connecting to the app again

```
$ kubectl set env -n webapp deployment friends --env DBHOST=mysql.backend.svc.cluster.local
deployment.apps/friends env updated
```

{% hint style="info" %}
Any changes to deployment to re-deploy the pod
{% endhint %}

11\. Access the application again and you should see the change.

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 2.46.20 pm.png>)

12\. Clean up

```
$ kubectl delete -f ~/kubernetes-101/labs/service/friends-app.yaml 
namespace "backend" deleted
namespace "webapp" deleted
deployment.apps "mysql" deleted
deployment.apps "friends" deleted
service "mysql" deleted
service "friends" deleted
pod "jump" deleted

```

_**That's how it's done**_ ✅&#x20;
