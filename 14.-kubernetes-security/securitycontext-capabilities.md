# SecurityContext Capabilities

When we come to using the container runtime in Kubernetes, these controls are used by the Kubernetes control plane to define which capabilities our container should be started with. The configuration for capabilities is surfaced to the user through various settings in the securityContext section of the YAML for a container. This configuration looks like:

```
securityContext:
      capabilities:
        drop:
          - all
        add: [“NET_ADMIN”]
```

In this case, we would be dropping all capabilities, and then adding in the `CAP_NET_ADMIN` capability. If the capabilities section in securityContext is empty, we’ll get the default set of capabilities defined by the container runtime, which would usually be fairly generous, and may well be much more than our application requires.&#x20;

```
[centos@ip-10-0-2-94 ~]$ kubectl exec -it hello-1 -- bash
bash-5.1# capsh --print
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
```

Lets see it more in action.
