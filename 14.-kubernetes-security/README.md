# 14. Kubernetes Security

## Service Accounts

By default the pods can authenticate by sending the contents of the file `/var/run/secrets/kubernetes.io/serviceaccount/token`, which is mounted into each container’s filesystem through a secret volume. The token file holds the ServiceAccount’s authentication token. When an app uses this token to connect to the API server, the authentication plugin authenticates the ServiceAccount and passes the ServiceAccount’s username back to the API server core.

Service-Account usernames are formatted like this:

```
system:serviceaccount:<namespace>:<service account name>
```

The API server passes this username to the configured authorization plugins, which determine whether the action the app is trying to perform is allowed to be performed by the ServiceAccount. These are nothing more than a way for an application running inside a pod to authenticate itself with the API server.

### Understanding ServiceAccount resource

* ServiceAccounts are resources just like Pods, Secrets, ConfigMaps, and so on, and are scoped to individual namespaces.
* A `default` ServiceAccount is automatically created for each namespace (that’s the one your pods have used all along).
* Every Pod uses the `default` ServiceAccount to contact the API server.
* This default ServiceAccount allows a resource to get information from the API server. The API server obtains this information from the system-wide authorization plugin configured by the cluster administrator. One of the available authorization plugins is the role-based access control (RBAC)plugin.
* Each Service Account uses a secret to automount API credentials
* Service accounts come with a secret that contains the API credentials
* By specifying the ServiceAccount to be used by a pod, the ServiceAccount secret is auto-mounted to provide API access credentials.
* Each pod is associated with exactly one ServiceAccount, but multiple pods can use the same ServiceAccount. As you can see in following image, **a pod can only use a ServiceAccount from the same namespace**.

![](https://www.golinuxcloud.com/wp-content/uploads/service\_account.jpg)

You can assign a ServiceAccount to a pod by specifying the account’s name in the pod manifest. If you don’t assign it explicitly, the pod will use the default ServiceAccount in the namespace.

### Creating ServiceAccount resource

A default ServiceAccount is automatically created for each namespace. You can list ServiceAccounts like you do other resources:

```
[centos@ip-10-0-2-94 ~]$ kubectl get sa
NAME      SECRETS   AGE
default   0         8d
[centos@ip-10-0-2-94 ~]$
```

You can also list the available ServiceAccount for all the namespaces in your cluster.

```
[centos@ip-10-0-2-94 ~]$ kubectl get sa --all-namespaces 
NAMESPACE         NAME                                 SECRETS   AGE
default           default                              0         8d
kube-node-lease   default                              0         8d
kube-public       default                              0         8d
kube-system       attachdetach-controller              0         8d
kube-system       bootstrap-signer                     0         8d
kube-system       calico-kube-controllers              0         8d
kube-system       calico-node                          0         8d
kube-system       certificate-controller               0         8d
kube-system       clusterrole-aggregation-controller   0         8d
kube-system       coredns                              0         8d
kube-system       cronjob-controller                   0         8d
kube-system       daemon-set-controller                0         8d
kube-system       default                              0         8d
kube-system       deployment-controller                0         8d
kube-system       disruption-controller                0         8d
kube-system       endpoint-controller                  0         8d
kube-system       endpointslice-controller             0         8d
...
...
...
```

Every namespace contains its own default ServiceAccount, but additional ones can be created if necessary. This is done mostly for improved security, Pods that don’t need to read any cluster metadata should run under a constrained account that doesn’t allow them to retrieve or modify any resources deployed in the cluster. Pods that need to retrieve resource metadata should run under a ServiceAccount that only allows reading those objects’ metadata, whereas pods that need to modify those objects should run under their own ServiceAccount allowing modifications of API objects.

You can create a ServiceAccount directly using `kubectl` command or by using a YAML file same as any other resources.

#### Method-1: Using kubectl command

To create a Service Account using kubectl, execute the following command on the controller node:

```
[centos@ip-10-0-2-94 ~]$ kubectl create serviceaccount sa1
serviceaccount/sa1 created
```

This command created a `sa1` ServiceAccount. To get the details of this ServiceAccount we can use `kubectl get sa` sa1 `-o yaml`:

```
[centos@ip-10-0-2-94 ~]$ kubectl get sa sa1 -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-07-05T01:26:14Z"
  name: sa1
  namespace: myapp
  resourceVersion: "1001144"
  uid: e1458595-166c-4fb9-8111-a258a041aeef
```

#### Method-2: Using YAML file

As we mentioned, you can use a YAML file to create a ServiceAccount same like any other resource type. Following is s simple YAML file to create `user2`ServiceAccount, you can add more data such as namespace, labels etc in this.

```
[centos@ip-10-0-2-94 ~]$ cat service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa2
```

Use `kubectl` to create this ServiceAccount:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f service-account.yaml
serviceaccount/sa2 created
```

By default, a pod can mount any Secret it wants. But the pod’s ServiceAccount can be configured to only allow the pod to mount Secrets that are listed as mountable Secrets on the Service-Account. To enable this feature, the ServiceAccount must contain the following annotation: `kubernetes.io/enforce-mountable-secrets="true"`. If the ServiceAccount is annotated with this annotation, any pods using it can mount only the ServiceAccount’s mountable Secrets—they can’t use any other Secret.

### Add ImagePullSecrets to a service account

If your images are available in a private registry (like, for example, the Docker Hub, Quay.io or a self-hosted registry), you will need to configure your Kubernetes cluster so that it is authorized to actually access these images. For this, you will add your registry credentials as a Secret object. For this, use the `kubectl create secret` command:

```
kubectl create secret docker-registry my-private-registry --docker-server https://index.docker.io/v1/ --docker-username <your-username> --docker-password <your-password> --docker-email <your-email>
```

In the code example above, `my-private-registry` is an arbitrarily chosen name for your set of Docker credentials. The `--docker-server` flag `https://index.docker.io/v1/` specifies the URL of the official Docker Hub. If you are using a third-party registry, remember to change this value accordingly.

You can create secrets for multiple registries (or multiple users for the same registry) if needed. The `kubelet` will combine all `ImagePullSecrets`. However, because pods can access secrets only in their own namespace, you must create a secret within each namespace where you want the pod to run.

You can now use this newly created Secret object when creating a new Pod, by adding an `imagePullSecrets` attribute to the Pod specification:

```
apiVersion: v1
kind: Pod
metadata:
  name: example-from-private-registry
spec:
  containers:
  - name: secret
    image: quay.io/devs-private-registry/secret-application:v1.2.3
  imagePullSecrets:
  - name: my-private-registry
```

Using the `imagePullSecrets` attribute also works when you are creating Pods using a StatefulSet or a Deployment controller.

### Assign ServiceAccount to a Pod

After you have created ServiceAccount, you can start assigning them to respective pods. You can use `spec.serviceAccountName` field in the pod definition to assign a ServiceAccount. Here I am creating a simple nginx pod using our sa`1` ServiceAccount.

```
[centos@ip-10-0-2-94 ~]$ cat pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: hello
  name: hello
spec:
  serviceAccount: sa1
  containers:
  - image: quay.io/mask365/scaling
    name: hello
    ports:
    - containerPort: 8080
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
[centos@ip-10-0-2-94 ~]$ 
```



###
