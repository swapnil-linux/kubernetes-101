# Kubernetes SecurityContext

## Overview

To enforce policies on the pod level, we can use Kubernetes SecurityContext field in the pod specification. A security context is used to define different privilege and access level control settings for any Pod or Container running inside the Pod.

Here are some of the settings which can be configured as part of Kubernetes SecurityContext field:

* **runAsUser** to specify the UID with which each container will run
* **runAsNonRoot** flag that will simply prevent starting containers that run as UID 0 or root.
* **runAsGroup** The GID to run the entrypoint of the container process
* **supplementalGroups** specify the Group (GID) for the first process in each container
* **fsGroup** we can specify the Group (GID) for filesystem ownership and new files. This can be applied for entire Pod and not on each container.
* **allowPrivilegeEscalation** controls whether any process inside the container can gain more privilege to perform the respective task.
* **readOnlyRootFilesystem** will mount the container root file system inside the Pod as read-only by default
* **capabilities** controls the different capabilities which can be added using 'add' or disabled using 'drop' keyword for the container
* **Seccomp**: Filter a process's system calls.
* **AppArmor**: Use program profiles to restrict the capabilities of individual programs.
* **Security Enhanced Linux (SELinux)** Objects are assigned security labels.

### Using runAsUser with Kubernetes SecurityContext

In this section we will explore the runAsUser field used with Kubernetes SecurityContext. The `runAsUser` can be applied at Pod Level or at Container Level. Let me demonstrate both these examples

#### Example-1: Define runAsUser for entire Pod

In this section we have a multi container pod where we will define runAsUser parameter under Kubernetes SecurityContext for all the containers running inside the Pod.

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/security/runasuser-pod.yml
apiVersion: v1
kind: Pod
metadata:
  name: pod-as-user-guest
spec:
  securityContext:
    runAsUser: 1025
  containers:
  - name: one
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
  - name: two
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
```

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/security/runasuser-pod.yml
pod/pod-as-user-guest created
```

Check the status of the Pod, so both our containers are in `Running` state:

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods pod-as-user-guest 
NAME                READY   STATUS    RESTARTS   AGE
pod-as-user-guest   2/2     Running   0          34s
```

We can connect to both the containers and verify the default user:

```
[centos@ip-10-0-2-94 ~]$ kubectl exec pod-as-user-guest -c one -- id
uid=1025(1025) gid=0(root)

[centos@ip-10-0-2-94 ~]$ kubectl exec pod-as-user-guest -c two -- id
uid=1025(1025) gid=0(root)
```

As expected, both the containers are running with the provided user id `defined`with `runAsUser` under Pod level Kubernetes SecurityContext.

#### Example-2: Define runAsUser for container

In this section now we will define different user for individual container inside the Kubernetes SecurityContext of the Pod definition file:

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/security/runasuser-con.yml
apiVersion: v1
kind: Pod
metadata:
  name: con-as-user-guest
spec:
  containers:
  - name: one
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1040
  - name: two
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1030
```

Here I have defined `runAsUser` separately for both the containers inside the Kubernetes SecurityContext so we will use different user for both the containers.

Create this Pod:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/security/runasuser-con.yml
pod/con-as-user-guest created
```

Check the status:

```
[centos@ip-10-0-2-94 ~]$ kubectl get pods con-as-user-guest 
NAME                READY   STATUS    RESTARTS   AGE
con-as-user-guest   2/2     Running   0          26s
```

Verify the USER ID of both the containers:

```
[centos@ip-10-0-2-94 ~]$ kubectl exec con-as-user-guest -c one -- id
uid=1040(1040) gid=0(root)

[centos@ip-10-0-2-94 ~]$ kubectl exec con-as-user-guest -c two -- id
uid=1030(1030) gid=0(root)
```

### Define common group of shared volumes in Kubernetes (fsGroup)

When we are sharing some volumes across multiple containers, then access permission can become a concern. In such scenarios we can use `fsGroup`under Kubernetes SecurityContext to define a common group which will act as an group owner for any such shared volumes.

NOTE:`fsGroup` is assigned at Pod level so you cannot assign it at container level Kubernetes `SecurityContext`, if you try to assign it at container level then you will get below error:

```
error: error validating "security-context-fsgroup-1.yaml": error validating data: [ValidationError(Pod.spec.containers[0].securityContext): unknown field "fsGroup" in io.k8s.api.core.v1.SecurityContext, ValidationError(Pod.spec.containers[1].securityContext): unknown field "fsGroup" in io.k8s.api.core.v1.SecurityContext]; if you choose to ignore these errors, turn validation off with --validate=false
```

This our sample YAML file to create a pod using `fsGroup`:

```yaml
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/security/pod-fsgroup.yml
apiVersion: v1
kind: Pod
metadata:
  name: pod-fsgroup
spec:
  securityContext:
    fsGroup: 555
  containers:
  - name: one
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1025
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
  - name: two
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1026
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
  volumes:
  - name: shared-volume
    emptyDir: {}
```

Create this pod:

```
[centos@ip-10-0-2-94 ~]$ kubectl create -f ~/kubernetes-101/labs/security/pod-fsgroup.yml
pod/pod-fsgroup created
```

Verify the group ownership on the shared volume:

```bash
[centos@ip-10-0-2-94 ~]$ kubectl exec pod-fsgroup -c one -- id
uid=1025(1025) gid=0(root) groups=555

[centos@ip-10-0-2-94 ~]$ kubectl exec pod-fsgroup -c one -- ls -ld /volume
drwxrwsrwx    2 root     555              6 Jul  5 04:58 /volume
```

So, one container one the `/volume` path is owned by `555` GID as expected. The `id` command shows the container is running with user ID `1025`, as specified in the pod definition. And UID 1025 is also member of group ID `555`&#x20;

One more thing which you should know that with `fsGroup` Kubernetes SecurityContext, any files created inside the shared volume will have group ownership of the ID provided in the pod definition file.&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl exec pod-fsgroup -c one -- touch /volume/test.txt
[centos@ip-10-0-2-94 ~]$ kubectl exec pod-fsgroup -c one -- ls -l /volume/
total 0
-rw-r--r--    1 1025     555              0 Jul  5 05:02 test.txt
[centos@ip-10-0-2-94 ~]$ 
```

As you can see, the `fsGroup` Kubernetes SecurityContext property is used when the process creates files in a volume (but this depends on the volume plugin used).

### Define supplementalGroups inside Kubernetes SecurityContext

We can combine `fsGroup` with `supplementalGroups` inside the Pod's SecurityContext field to define some additional groups. In such case the `runAsUser` or the default image user will also be added to these supplementary groups.

```
[centos@ip-10-0-2-94 ~]$ cat ~/kubernetes-101/labs/security/pod-supgrp.yml
apiVersion: v1
kind: Pod
metadata:
  name: pod-supgrp
spec:
  securityContext:
    fsGroup: 555
    supplementalGroups: [666, 777]
  containers:
  - name: one
    image: alpine:latest
    command: ["/bin/sleep", "999999"]
    securityContext:
...
...
```

```
[centos@ip-10-0-2-94 ~]$ kubectl exec pod-supgrp -c one -- id
uid=1025(1025) gid=0(root) groups=555,666,777
```

So now along with `fsGroup`, our user has also been added to additional supplementary groups.
