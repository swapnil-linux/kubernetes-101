# Lab: Access API server using ServiceAccount within Pod

1. Let's create a namespace and set the context to it.

```
[centos@ip-10-0-2-94 ~]$ kubectl create namespace security-lab
namespace/security-lab created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl config set-context --current --namespace security-lab
Context "kubernetes-admin@kubernetes" modified.
```

2\. List the existing service accounts and create a new one

```
[centos@ip-10-0-2-94 ~]$ kubectl get sa
NAME      SECRETS   AGE
default   0         2m50s
```

```
[centos@ip-10-0-2-94 ~]$ kubectl create serviceaccount newsa1
serviceaccount/newsa1 created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get sa
NAME      SECRETS   AGE
default   0         3m13s
newsa1    0         7s
```

3\. Create a pod with the default service account

```
[centos@ip-10-0-2-94 ~]$ kubectl run hello-1 --image=quay.io/mask365/scaling 
pod/hello-1 created
```

4\. Create another one with the new service account.

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/security/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: hello-2
  name: hello-2
spec:
  serviceAccount: newsa1
  containers:
  - image: quay.io/mask365/scaling
    name: hello
    ports:
    - containerPort: 8080
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/security/pod.yaml
pod/hello-2 created
```

5\. compare the tokens in both pods

```
[centos@ip-10-0-2-94 ~]$ kubectl exec hello-1 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
eyJhbGciOiJSUzI1NiIsImtpZCI6Ilp2MC1OVUFsNjU3c0NXTU9ESC1UWV9nMmt0cWFNUUpvSm5KV0IxM3IxODQifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjg4NTI3MzA0LCJpYXQiOjE2NTY5OTEzMDQsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJzZWN1cml0eS1sYWIiLCJwb2QiOnsibmFtZSI6ImhlbGxvLTEiLCJ1aWQiOiJjYTVhMjU4Ny0wOWFkLTRhMjItOWY0My0wOGU1MmM3MGM5ZWQifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRlZmF1bHQiLCJ1aWQiOiIyODNhNzk3ZC02MmVkLTRkNjUtOTJhMS0zZGQ5YmFlMzU1MzMifSwid2FybmFmdGVyIjoxNjU2OTk0OTExfSwibmJmIjoxNjU2OTkxMzA0LCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6c2VjdXJpdHktbGFiOmRlZmF1bHQifQ.twEO-QoQEuDtjKYjZW2W35MZwkgmgqVm_a6B04vaprHaGFnHq1G871zz5WB3BLcuaGB6U4-DLNfN8yjjhPAvk62cCqx7HVvl3_ypndE4bM8M3rihXQ6Gtiuc_dFuMcvlBo-gX9Kn1LaqXhYexnq8i24mgy3Yvp-sO5v_0O6ie9vO3g_jgtLtHjDC2QrHpTTjYrTQjDnUJ_3DmPNDxW-6OLanvWsd6m3uKMDZnG7ir7rXtG41qM8vdUhlpRIBwyDSYuwgb22oEjg_Rv8iOKZw4ABpyeeA9XARAvbR4rmOoiXDAUElBFn0Oj6jKTaGth4WMU7PF6FixFccrFbVu-C0ng
```

```
[centos@ip-10-0-2-94 ~]$ kubectl exec hello-2 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
eyJhbGciOiJSUzI1NiIsImtpZCI6Ilp2MC1OVUFsNjU3c0NXTU9ESC1UWV9nMmt0cWFNUUpvSm5KV0IxM3IxODQifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjg4NTI3NDYwLCJpYXQiOjE2NTY5OTE0NjAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJzZWN1cml0eS1sYWIiLCJwb2QiOnsibmFtZSI6ImhlbGxvLTIiLCJ1aWQiOiJlYmQ2MTAzZC1hYTRjLTQ4YWMtYTcwNy0zZTE1MTU4MTE4YTEifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6Im5ld3NhMSIsInVpZCI6IjlhNTE0ZjcwLTZlNWItNDZhNy1iN2E1LTRjYjM5NDY1M2U2YyJ9LCJ3YXJuYWZ0ZXIiOjE2NTY5OTUwNjd9LCJuYmYiOjE2NTY5OTE0NjAsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpzZWN1cml0eS1sYWI6bmV3c2ExIn0.S9McN9eeE69AMNog2hZHasTr843Hz01hS3QRHADHp_zBY9glRRK93wtuba3gx05Tnzeo7rBfsryb1pPenKJrZw-9x7uvvceE7Ke0NKqmNqyA9sb8vqZ8XBr4cP2bA6bM5qO6u0je8JClsL1PseqV1s-WCzelW6wV9M722g7yHI4vL8phd42oMDqtnx1My8XfM5oyV0u9TJYdR5QLIK4_cLTh3uH5-qlWsoKNyXx8qXVXPUcMa-iUtjARW98Zei860_To8WnEhrc936mL6dHeudeEIVWEuINTrOl3DN8XPursYPV5jkBDhpwjnOiCsukELiD4FyFsVbOPk3GLR428Ag
```

6\. Access `hello-2` pod, and make sure that you are able to resolve `kubernetes.default` using CoreDNS.

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -it hello-2 -- bash
bash-5.1#
```

```
bash-5.1# nslookup kubernetes.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1

```

7\. Now let us try to access our API server using `curl`:

```
bash-5.1# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes.default.svc.cluster.local/api/v1/
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/api/v1/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}bash-5.1# 
```

As you see we are getting a Forbidden error message because a normal user is not allowed to access the API server so we must use our secret token of `newsa1` ServiceAccount along with the CA certificate inside the `serviceaccount`directory:

```
bash-5.1# curl -cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc.cluster.local/api/v1
{
  "kind": "APIResourceList",
  "groupVersion": "v1",
  "resources": [
    {
      "name": "bindings",
      "singularName": "",
      "namespaced": true,
      "kind": "Binding",
      "verbs": [
        "create"
      ]
    },
    {
      "name": "componentstatuses",
      "singularName": "",
      "namespaced": false,
      "kind": "ComponentStatus",
      "verbs": [
        "get",
        "list"
      ],
...
...
...
...
```

As you can see, we were able to contact the kubernetes API server using the service account token, and it gives a long list of available APIs. You can go ahead and check individual APIs from this list such as available resources:



8\. A ClusterRole resource defines what actions can be taken on which resources in the entire cluster. Let's create a separate ClusterRole that allows to list the Pods

```
[centos@ip-10-0-2-94 ~]$ cat kubernetes-101/labs/security/clusterrole-list-pods.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: pod-reader
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
```

Use `kubectl` command to create this role:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f kubernetes-101/labs/security/clusterrole-list-pods.yml
clusterrole.rbac.authorization.k8s.io/pod-reader created
```

9\. A Role defines what actions can be performed, but it doesn’t specify who can perform them. To do that, you must bind the Role to a subject, which can be a user, a Service-Account, or a group (of users or ServiceAccounts).

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/security/clusterrolebinding.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: list-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: newsa1
  namespace: security-lab
```

Create and list the ClusterRoleBinding:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/security/clusterrolebinding.yml
clusterrolebinding.rbac.authorization.k8s.io/list-pods created
```

```
[centos@ip-10-0-2-94 ~]$ kubectl get clusterrolebindings list-pods -o wide
NAME        ROLE                     AGE   USERS   GROUPS   SERVICEACCOUNTS
list-pods   ClusterRole/pod-reader   39s                    security-lab/newsa1
```

10\. From pod hello-1, try listing pods of namespace  `kube-system`

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -it hello-1 -- bash
bash-5.1# 
```

```
bash-5.1# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/kube-system/pods
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:security-lab:default\" cannot list resource \"pods\" in API group \"\" in the namespace \"kube-system\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
}
```

{% hint style="info" %}
default service account is not able to list pods from another namespace
{% endhint %}

11\. Now try doing the same from `hello-2` pod

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -it hello-2 -- bash
bash-5.1# 
```

```
bash-5.1# curl -s --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/kube-system/pods | head -n20
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "1019796"
  },
  "items": [
    {
      "metadata": {
        "name": "calico-kube-controllers-6766647d54-vxt5v",
        "generateName": "calico-kube-controllers-6766647d54-",
        "namespace": "kube-system",
        "uid": "774cae0a-c9de-4f81-9381-869a6615152f",
        "resourceVersion": "742203",
        "creationTimestamp": "2022-06-26T11:17:47Z",
        "labels": {
          "k8s-app": "calico-kube-controllers",
          "pod-template-hash": "6766647d54"
        },
        "annotations": {
```

**Thats it** 😃&#x20;
