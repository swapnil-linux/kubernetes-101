# Lab: Ingress

1.  The NGINX Ingress controller is installed from a YAML file hosted in the Kubernetes GitHub repo. It installs a bunch of Kubernetes constructs including a Namespace, ServiceAccounts, ConfigMap, Roles, RoleBindings, and more.

    Install it with the following command.\


```
[centos@ip-10-0-2-94 ~]$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/1.23/deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created

```

2\. Check the `ingress-nginx` Namespace to make sure the controller Pod is running. It may take a few moments to enter the running phase.

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n ingress-nginx
NAME                                       READY   STATUS              RESTARTS   AGE
ingress-nginx-admission-create-cqjn5       0/1     Completed           0          28s
ingress-nginx-admission-patch-6ntmq        0/1     Completed           0          27s
ingress-nginx-controller-8fb79d7df-j96m2   0/1     ContainerCreating   0          28s

[centos@ip-10-0-2-94 ~]$ kubectl get pods -n ingress-nginx
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-cqjn5       0/1     Completed   0          32s
ingress-nginx-admission-patch-6ntmq        0/1     Completed   0          31s
ingress-nginx-controller-8fb79d7df-j96m2   1/1     Running     0          47s

```

3\. You’ll have at least one Ingress class, called “nginx” that was created when you installed the NGINX controller.

```
[centos@ip-10-0-2-94 ~]$ kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       39m
[centos@ip-10-0-2-94 ~]$ 
```

4\. Lets make our controller listen on port 80/443 of the host. To do this edit the deployment of the controller and add the below line under `template.spec`

`hostNetwork: true`

```
kubectl edit deployments.apps ingress-nginx-controller  -n ingress-nginx
```

```
   spec:
      hostNetwork: true       <<==== add this line here
      containers:
```

5\. notice the change in IP of the pod

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods -n ingress-nginx  -o wide -w
NAME                                       READY   STATUS        RESTARTS   AGE   IP             NODE                                           NOMINATED NODE   READINESS GATES
ingress-nginx-admission-create-cqjn5       0/1     Completed     0          90m   10.244.44.30   ip-10-0-2-94.ap-southeast-2.compute.internal   <none>           <none>
ingress-nginx-admission-patch-6ntmq        0/1     Completed     0          90m   10.244.44.31   ip-10-0-2-94.ap-southeast-2.compute.internal   <none>           <none>
ingress-nginx-controller-76c47cbdb-5h69j   1/1     Running       0          18s   10.0.2.94      ip-10-0-2-94.ap-southeast-2.compute.internal   <none>           <none>
ingress-nginx-controller-8fb79d7df-j96m2   1/1     Terminating   0          90m   10.244.44.32   ip-10-0-2-94.ap-southeast-2.compute.internal   <none>           <none>
```

6\. Lets deploy our friends app again with a slight change.&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/ingress/friends-app.yaml 
namespace/backend created
namespace/webapp created
deployment.apps/mysql created
deployment.apps/friends created
service/mysql created
service/friends created
[centos@ip-10-0-2-94 ~]$ 
```

7\. Lets deploy scaling app in `myapp` namespace, and expose the service

```
[centos@ip-10-0-2-94 ~]$ kubectl create deployment scaling  --image=quay.io/mask365/scaling --port 8080 -n myapp
deployment.apps/scaling created
[centos@ip-10-0-2-94 ~]$ 
```

```
[centos@ip-10-0-2-94 ~]$ kubectl expose deployment scaling -n myapp
service/scaling exposed
[centos@ip-10-0-2-94 ~]$ 
```

8\. Now is the time to create ingress for both apps

```
[centos@ip-10-0-2-94 ~]$ kubectl create ingress friends --class=nginx  --rule="friends.cloud.googlinux.com/*=friends:8080" -n webapp
ingress.networking.k8s.io/friends created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl create ingress scaling --class=nginx  --rule="scaling.cloud.googlinux.com/*=scaling:8080" -n myapp
ingress.networking.k8s.io/scaling created
```

9\. Wait for the ingress controller to acquire the IP and try accessing the application using the domain name from your browser.

```
[centos@ip-10-0-2-94 ~]$ kubectl get ing --all-namespaces 
NAMESPACE   NAME      CLASS   HOSTS                         ADDRESS     PORTS   AGE
myapp       scaling   nginx   scaling.cloud.googlinux.com   10.0.2.94   80      49s
webapp      friends   nginx   friends.cloud.googlinux.com   10.0.2.94   80      74s
[centos@ip-10-0-2-94 ~]$
```

{% hint style="info" %}
during this example, I have created a wildcard DNS record for `*.cloud.googlinux.com` pointing to my K8S master

If you are not able to manage DNS, create a host entry in `/etc/hosts` file for both domains
{% endhint %}

10\. Clean Up.

```
[centos@ip-10-0-2-94 ~]$ kubectl delete all --all -n myapp
pod "scaling-dbbc8fcdd-9pjhh" deleted
service "scaling" deleted
deployment.apps "scaling" deleted
[centos@ip-10-0-2-94 ~]$
```

```
[centos@ip-10-0-2-94 ~]$ kubectl delete -f ~/kubernetes-101/labs/ingress/friends-app.yaml 
namespace "backend" deleted
namespace "webapp" deleted
deployment.apps "mysql" deleted
deployment.apps "friends" deleted
service "mysql" deleted
service "friends" deleted
[centos@ip-10-0-2-94 ~]$ 
```

Optionally delete the ingress controller if you plan to no longer use it.

```
[centos@ip-10-0-2-94 ~]$ kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/1.23/deploy.yaml
namespace "ingress-nginx" deleted
serviceaccount "ingress-nginx" deleted
serviceaccount "ingress-nginx-admission" deleted
role.rbac.authorization.k8s.io "ingress-nginx" deleted
role.rbac.authorization.k8s.io "ingress-nginx-admission" deleted
clusterrole.rbac.authorization.k8s.io "ingress-nginx" deleted
clusterrole.rbac.authorization.k8s.io "ingress-nginx-admission" deleted
rolebinding.rbac.authorization.k8s.io "ingress-nginx" deleted
rolebinding.rbac.authorization.k8s.io "ingress-nginx-admission" deleted
clusterrolebinding.rbac.authorization.k8s.io "ingress-nginx" deleted
clusterrolebinding.rbac.authorization.k8s.io "ingress-nginx-admission" deleted
configmap "ingress-nginx-controller" deleted
service "ingress-nginx-controller" deleted
service "ingress-nginx-controller-admission" deleted
deployment.apps "ingress-nginx-controller" deleted
job.batch "ingress-nginx-admission-create" deleted
job.batch "ingress-nginx-admission-patch" deleted
ingressclass.networking.k8s.io "nginx" deleted
validatingwebhookconfiguration.admissionregistration.k8s.io "ingress-nginx-admission" deleted
```

**Cool** 😎&#x20;
