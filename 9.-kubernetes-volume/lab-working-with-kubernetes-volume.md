# Lab: Working with Kubernetes Volume

1. Create a folder `/nfsdata` on the control-plane node which we will use as a persistent storage

```
sudo mkdir /nfsdata
```

```
sudo yum install nfs-utils -y
```

2\. Create a pod that will act as NFS server for this exercise.

```
$ kubectl create -f ~/kubernetes-101/labs/storage/nfs-server.yml 
namespace/nfs-on-k8s created
pod/nfs-server created
```

3\. Change the context to the namespace `nfs-on-k8s`

```
$ kubectl config set-context --current --namespace nfs-on-k8s
Context "kubernetes-admin@kubernetes" modified.
```

4\. Next we will deploy nfs-provisioner using helm charts

Install Helm

```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

The NFS subdir external provisioner is an automatic provisioner for Kubernetes that uses your _already configured_ NFS server, automatically creating Persistent Volumes.

```
$ helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
"nfs-subdir-external-provisioner" has been added to your repositories
```

```
$ helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=`hostname` --set nfs.path=/
NAME: nfs-subdir-external-provisioner
LAST DEPLOYED: Sun Jul  3 11:20:36 2022
NAMESPACE: nfs-on-k8s
STATUS: deployed
REVISION: 1
TEST SUITE: None

```

5\. Wait for the pods to be up and running, this might take a while

```
$ kubectl get pods
NAME                                               READY   STATUS    RESTARTS   AGE
nfs-server                                         1/1     Running   0          59s
nfs-subdir-external-provisioner-84b5776c89-gjl22   1/1     Running   0          19m
```

6\. Helm install has also created a storageclass for provisioning nfs volumes

```
$ kubectl get sc
NAME         PROVISIONER                                     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-client   cluster.local/nfs-subdir-external-provisioner   Delete          Immediate           true                   27m
```

7\. Create a PVC for persistent storage for our mysql pod

```
$ kubectl create -f ~/kubernetes-101/labs/storage/pvc.yml 
namespace/myapp2 created
persistentvolumeclaim/pvc001 created
```

```
$ kubectl get pvc -n myapp2
NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc001   Bound    pvc-2bcd28cf-56d0-4813-b97f-0d5865717408   1Mi        RWX            nfs-client     52s

```

```
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM           STORAGECLASS   REASON   AGE
pvc-2bcd28cf-56d0-4813-b97f-0d5865717408   1Mi        RWX            Delete           Bound    myapp2/pvc001   nfs-client              67s

```

```
$ ls /nfsdata/
myapp2-pvc001-pvc-2bcd28cf-56d0-4813-b97f-0d5865717408
```

8\. Lets deploy a app which will utilize this pvc

```
$ kubectl create -f ~/kubernetes-101/labs/storage/friends-app-persistent.yaml 
deployment.apps/mysql created
deployment.apps/friends created
service/mysql created
service/friends created

```

```
$ kubectl get all -n myapp2
NAME                           READY   STATUS    RESTARTS   AGE
pod/friends-7c97468766-wzvrs   1/1     Running   0          30s
pod/mysql-698b97459f-7b64p     1/1     Running   0          30s

NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
service/friends   NodePort    10.96.58.168   <none>        8080:30200/TCP   30s
service/mysql     ClusterIP   10.96.226.10   <none>        3306/TCP         30s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/friends   1/1     1            1           30s
deployment.apps/mysql     1/1     1            1           30s

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/friends-7c97468766   1         1         1       30s
replicaset.apps/mysql-698b97459f     1         1         1       30s

```

9\. Lets create a table and insert a few records in our mysql database

{% hint style="info" %}
**Note:** replace the pod name with your mysql pod name
{% endhint %}

```
kubectl -n myapp2 cp ~/kubernetes-101/labs/service/friends.sql mysql-698b97459f-7b64p:/tmp/
```

```
$ kubectl -n myapp2 exec -it mysql-698b97459f-7b64p -- bash
root@mysql-698b97459f-7b64p:/# 
```

```
root@mysql-698b97459f-7b64p:/# mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} friends < /tmp/friends.sql 
mysql: [Warning] Using a password on the command line interface can be insecure.
root@mysql-698b97459f-7b64p:/#
```

10\. Visit the application from a browser and you should be able to see the records.

![](<../.gitbook/assets/Screen Shot 2022-07-03 at 10.23.27 pm.png>)

11\. Lets delete our mysql pod and check if we are still able to access our application and the data

```
$ kubectl -n myapp2 delete pod mysql-698b97459f-7b64p 
pod "mysql-698b97459f-7b64p" deleted
```

we have a new pod up and running

```
$ kubectl get pods -n myapp2
NAME                       READY   STATUS    RESTARTS   AGE
friends-7c97468766-wzvrs   1/1     Running   0          9m18s
mysql-698b97459f-kc5xx     1/1     Running   0          24s
```

and using the same persistent storage

```
$ kubectl exec -n myapp2 mysql-698b97459f-kc5xx -- df -h /var/lib/mysql
Filesystem                                                                                            Size  Used Avail Use% Mounted on
ip-10-0-2-94.ap-southeast-2.compute.internal:/myapp2-pvc001-pvc-2bcd28cf-56d0-4813-b97f-0d5865717408   50G  6.6G   44G  14% /var/lib/mysql
[centos@ip-10-0-2-94 ~]$ 
```

12\. Clean Up

```
$ kubectl delete all --all -n myapp2
pod "friends-7c97468766-wzvrs" deleted
pod "mysql-698b97459f-kc5xx" deleted
service "friends" deleted
service "mysql" deleted
deployment.apps "friends" deleted
deployment.apps "mysql" deleted
[centos@ip-10-0-2-94 ~]$ 
```

this will not delete the persistent resource like PVC, so we have to delete is manually

```
$ kubectl -n myapp2 delete pvc pvc001 
persistentvolumeclaim "pvc001" deleted
```

pv gets deleted automatically due to the reclaim policy

```
$ kubectl get pv
No resources found
```

**that's magic** 🪄&#x20;

