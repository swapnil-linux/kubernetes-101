# Lab: Privileged Pod & Capabilities

1. Let's create a pod and check its capabilities.

```
[centos@ip-10-0-2-94 ~]$ kubectl run alpine -it --image=alpine -- sh 
If you don't see a command prompt, try pressing enter.
/ # 
```

```
/ # apk add libcap
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/community/x86_64/APKINDEX.tar.gz
(1/1) Installing libcap (2.64-r0)
Executing busybox-1.35.0-r13.trigger
OK: 6 MiB in 15 packages
```

```
/ # capsh --print
Current: cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service=ep
Bounding set =cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service
Ambient set =
Current IAB: !cap_dac_read_search,!cap_linux_immutable,!cap_net_broadcast,!cap_net_admin,!cap_net_raw,!cap_ipc_lock,!cap_ipc_owner,!cap_sys_module,!cap_sys_rawio,!cap_sys_chroot,!cap_sys_ptrace,!cap_sys_pacct,!cap_sys_admin,!cap_sys_boot,!cap_sys_nice,!cap_sys_resource,!cap_sys_time,!cap_sys_tty_config,!cap_mknod,!cap_lease,!cap_audit_write,!cap_audit_control,!cap_setfcap,!cap_mac_override,!cap_mac_admin,!cap_syslog,!cap_wake_alarm,!cap_block_suspend
Securebits: 00/0x0/1'b0 (no-new-privs=0)
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=0(root) euid=0(root)
gid=0(root)
groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
Guessed mode: HYBRID (4)
/ # 

```

2\. Lets try to ping from the pod

```
/ # ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
ping: permission denied (are you root?)
/ #
```

Inspite of being root we are not able to ping as the pod lacks NET\_BROADCAST capability.

3\. Lets create a Privileged Pod and try the same

```
$ cat ~/kubernetes-101/labs/security/pod-priv.yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-priv
  name: pod-priv
spec:
  containers:
  - args:
    - sleep
    - "999999"
    image: alpine
    name: pod-priv
    resources: {}
    securityContext:
      privileged: true
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

```
$ kubectl create -f ~/kubernetes-101/labs/security/pod-priv.yml
pod/pod-priv created
```

```
$ kubectl exec -it pod-priv -- sh
/ # 
```

```
/ # apk add libcap
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/community/x86_64/APKINDEX.tar.gz
(1/1) Installing libcap (2.64-r0)
Executing busybox-1.35.0-r13.trigger
OK: 6 MiB in 15 packages
```

```
/ # capsh --print
Current: =eip
Bounding set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend
Ambient set =cap_chown,cap_dac_override,cap_dac_read_search,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_linux_immutable,cap_net_bind_service,cap_net_broadcast,cap_net_admin,cap_net_raw,cap_ipc_lock,cap_ipc_owner,cap_sys_module,cap_sys_rawio,cap_sys_chroot,cap_sys_ptrace,cap_sys_pacct,cap_sys_admin,cap_sys_boot,cap_sys_nice,cap_sys_resource,cap_sys_time,cap_sys_tty_config,cap_mknod,cap_lease,cap_audit_write,cap_audit_control,cap_setfcap,cap_mac_override,cap_mac_admin,cap_syslog,cap_wake_alarm,cap_block_suspend
Current IAB: ^cap_chown,^cap_dac_override,^cap_dac_read_search,^cap_fowner,^cap_fsetid,^cap_kill,^cap_setgid,^cap_setuid,^cap_setpcap,^cap_linux_immutable,^cap_net_bind_service,^cap_net_broadcast,^cap_net_admin,^cap_net_raw,^cap_ipc_lock,^cap_ipc_owner,^cap_sys_module,^cap_sys_rawio,^cap_sys_chroot,^cap_sys_ptrace,^cap_sys_pacct,^cap_sys_admin,^cap_sys_boot,^cap_sys_nice,^cap_sys_resource,^cap_sys_time,^cap_sys_tty_config,^cap_mknod,^cap_lease,^cap_audit_write,^cap_audit_control,^cap_setfcap,^cap_mac_override,^cap_mac_admin,^cap_syslog,^cap_wake_alarm,^cap_block_suspend
Securebits: 00/0x0/1'b0 (no-new-privs=0)
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=0(root) euid=0(root)
gid=0(root)
groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
Guessed mode: HYBRID (4)
/ # 

```

```
/ # ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: seq=0 ttl=107 time=1.253 ms
64 bytes from 8.8.8.8: seq=1 ttl=107 time=1.231 ms
^C
--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 1.231/1.242/1.253 ms
/ # 
```

As there are much more capabilities, we are able to ping.

4\. Lets create another pod, only with the required capability

```
$ cat ~/kubernetes-101/labs/security/pod-ping.yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-ping
  name: pod-ping
spec:
  containers:
  - args:
    - sleep
    - "999999"
    image: alpine
    name: pod-ping
    resources: {}
    securityContext:
      capabilities:
        add:
          - NET_BROADCAST
          - NET_RAW
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

As you can check under capabilities section, I have explicitly allowed `NET_BROADCAST` and `NET_RAW` capability for this pod.

Let's create this pod:

```
$ kubectl create -f ~/kubernetes-101/labs/security/pod-ping.yml
pod/pod-ping created
```

5\. Lets check the capabilities and try ping.

```
$ kubectl exec -it pod-ping -- sh
/ # 
```

```
/ # apk add libcap
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/community/x86_64/APKINDEX.tar.gz
(1/1) Installing libcap (2.64-r0)
Executing busybox-1.35.0-r13.trigger
OK: 6 MiB in 15 packages



/ # ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: seq=0 ttl=107 time=1.479 ms
64 bytes from 8.8.8.8: seq=1 ttl=107 time=1.503 ms
64 bytes from 8.8.8.8: seq=2 ttl=107 time=1.528 ms
64 bytes from 8.8.8.8: seq=3 ttl=107 time=1.748 ms
^C
--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 1.479/1.564/1.748 ms



/ # capsh --print
Current: cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_broadcast,cap_net_raw=ep
Bounding set =cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_broadcast,cap_net_raw
Ambient set =
Current IAB: !cap_dac_read_search,!cap_linux_immutable,!cap_net_admin,!cap_ipc_lock,!cap_ipc_owner,!cap_sys_module,!cap_sys_rawio,!cap_sys_chroot,!cap_sys_ptrace,!cap_sys_pacct,!cap_sys_admin,!cap_sys_boot,!cap_sys_nice,!cap_sys_resource,!cap_sys_time,!cap_sys_tty_config,!cap_mknod,!cap_lease,!cap_audit_write,!cap_audit_control,!cap_setfcap,!cap_mac_override,!cap_mac_admin,!cap_syslog,!cap_wake_alarm,!cap_block_suspend
Securebits: 00/0x0/1'b0 (no-new-privs=0)
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=0(root) euid=0(root)
gid=0(root)
groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
Guessed mode: HYBRID (4)
/ # 

```

6\.  Let's create another pod with no capabilities.

```
$ cat ~/kubernetes-101/labs/security/pod-nocap.yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-nocap
  name: pod-nocap
spec:
  containers:
  - args:
    - sleep
    - "999999"
    image: alpine
    name: pod-nocap
    resources: {}
    securityContext:
      capabilities:
        drop:
          - ALL
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

```
$ kubectl create -f ~/kubernetes-101/labs/security/pod-nocap.yml
pod/pod-nocap created
```

7\. And lets check the capabilities

```
$ kubectl exec -it pod-nocap -- sh
/ #
```

```
/ # apk add libcap
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.16/community/x86_64/APKINDEX.tar.gz
(1/1) Installing libcap (2.64-r0)
Executing busybox-1.35.0-r13.trigger
OK: 6 MiB in 15 packages
```

```
/ # capsh --print
Current: =
Bounding set =
Ambient set =
Current IAB: !cap_chown,!cap_dac_override,!cap_dac_read_search,!cap_fowner,!cap_fsetid,!cap_kill,!cap_setgid,!cap_setuid,!cap_setpcap,!cap_linux_immutable,!cap_net_bind_service,!cap_net_broadcast,!cap_net_admin,!cap_net_raw,!cap_ipc_lock,!cap_ipc_owner,!cap_sys_module,!cap_sys_rawio,!cap_sys_chroot,!cap_sys_ptrace,!cap_sys_pacct,!cap_sys_admin,!cap_sys_boot,!cap_sys_nice,!cap_sys_resource,!cap_sys_time,!cap_sys_tty_config,!cap_mknod,!cap_lease,!cap_audit_write,!cap_audit_control,!cap_setfcap,!cap_mac_override,!cap_mac_admin,!cap_syslog,!cap_wake_alarm,!cap_block_suspend
Securebits: 00/0x0/1'b0 (no-new-privs=0)
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=0(root) euid=0(root)
gid=0(root)
groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
Guessed mode: HYBRID (4)
/ # 

```

8\. As there are no capabilities, lets try a few things.

```
/ # touch /tmp/test.txt
/ # chown 1000 /tmp/test.txt
chown: /tmp/test.txt: Operation not permitted
```

```
/ # adduser test-user
adduser: /home/test-user: Operation not permitted
adduser: /home/test-user: Operation not permitted
adduser: /home/test-user: Operation not permitted
Changing password for test-user
New password: 
Bad password: too short
Retype password: 
passwd: password for test-user changed by root
/ # cd /home/
/home # ls
test-user
/home # ls -l
total 0
drwxr-xr-x    2 root     root             6 Jul  5 06:29 test-user
```

9\. Clean Up.

```
$ kubectl delete all --all -n security-lab 
pod "alpine" deleted
pod "con-as-user-guest" deleted
pod "hello-1" deleted
pod "hello-2" deleted
pod "pod-as-user-guest" deleted
pod "pod-fsgroup" deleted
pod "pod-nocap" deleted
pod "pod-ping" deleted
pod "pod-priv" deleted
pod "pod-supgrp" deleted
```

**I am done** :thumbsup:
