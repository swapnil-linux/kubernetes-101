# 10. ConfigMaps and Secrets

## Config Maps

Imagine that you are developing an application that you can run on your own computer (for development) and in the cloud (to handle real traffic). You write the code to look in an environment variable named `DATABASE_HOST`. Locally, you set that variable to `localhost`. In the cloud, you set it to refer to a Kubernetes Service that exposes the database component to your cluster. This lets you fetch a container image running in the cloud and debug the exact same code locally if needed.

Kubernetes provides an object called a ConfigMap (CM) that lets you store configuration data outside of a Pod. It also makes it easy to inject the config into Pods at run-time.

ConfigMaps are first-class objects in the Kubernetes API under the core API group, and they’re v1. This tells us a lot of things:

1. They’re stable (v1)
2. They’ve been around for a while (the fact that they’re in the core API group).
3. You can operate on them with the usual kubectl commands.&#x20;
4. They can be defined and deployed via the usual YAML manifests

ConfigMaps are typically used to store non-sensitive configuration data such as:

* Environment variables
* Configuration files (things like web server configs and database configs)&#x20;
* Hostnames
* Service ports
* Accounts names

You should not use ConfigMaps to store sensitive data such as certificates and passwords. Kubernetes provides a different object, called a Secret, for storing sensitive data. Secrets and ConfigMaps are very similar in design and implementation, the major difference is that Kubernetes takes steps to obscure the data stored in Secrets. It makes no such efforts to obscure data in ConfigMaps.

### How ConfigMaps work

At a high level, a ConfigMap is a place to store configuration data that can be seamlessly injected into containers at runtime. As far as apps are concerned, there is no ConfigMap. The config data is simply where it’s expected and the app has no idea it was put there by a ConfigMap.

Let’s look a bit closer...

Behind the scenes, ConfigMaps are a map of key-value pairs and we call each pair an entry.



* **Keys** are an arbitrary name that can be created from alphanumerics, dashes, dots, and underscores
* **Values** can contain anything, including multiple lines with carriage returns
* Keys and values are separated by a colon – key:value

Some simple examples might be:

• db-port:13306\
• hostname:msb-prd-db1

Once data is stored in a ConfigMap, it can be injected into containers at run-time via any of the following methods:

* Environment variables
* Arguments to the container’s startup command&#x20;
* Files in a volume

All of the methods work seamlessly with existing applications. In fact, all an application sees is its configuration data in either; an environment variable, an argument to a startup command, or a file in a filesystem. The application is unaware the data originally came from a ConfigMap.

\


![](<../.gitbook/assets/Screen Shot 2022-07-03 at 8.18.12 am.png>)

### ConfigMaps and environment variables

A common way to get ConfigMap data into a container is via environment variables. You create the ConfigMap, then you map its entries into environment variables in the container section of a Pod template. When the container starts, the environment variables appear in the container as standard Linux or Windows environment variables and the app just uses them as normal.

![](<../.gitbook/assets/Screen Shot 2022-07-03 at 8.20.30 am.png>)

When the Pod is scheduled and the container started, FIRSTNAME and LASTNAME will be created as standard Linux environment variables inside the container. Applications can use these like regular environment variables – because they are!

Run the following commands to deploy a Pod from the envpod.yml file and list environment variables that include the NAME string in their name. This will list the FIRSTNAME and LASTNAME variables and you’ll see they’re populated with the values from the multimap ConfigMap.

{% hint style="info" %}
A drawback to using ConfigMaps with environment variables is that environment variables are static. This means updates made to the map don’t get reflected in running containers. For example, if you update the values of the given and family entries in the ConfigMap, environment variables in existing containers won’t see the updates.
{% endhint %}

### ConfigMaps and container startup commands

The concept of using ConfigMaps with container startup commands is simple. You specify the startup command for a container in the Pod template and then customize it with variables.

```
spec:
  containers:
    - name: args1
      image: busybox
      command: [ "/bin/sh", "-c", "echo First name $(FIRSTNAME) last name $(LASTNAME)" ]
      env:
        - name: FIRSTNAME
          valueFrom:
            configMapKeyRef:
              name: multimap
              key: given
        - name: LASTNAME
          valueFrom:
            configMapKeyRef:
              name: multimap
              key: family
```

![](<../.gitbook/assets/Screen Shot 2022-07-03 at 8.24.45 am.png>)

Using ConfigMaps with container startup commands is an extension of environment variables. As such, it suffers from the same limitations – updates to map entries won’t be reflected in running containers.

If you ran the startup-pod it should be in the completed state. This is because it’s startup command runs and completes, causing the Pod to succeed. Delete it with kubectl delete pod startup-pod.

### ConfigMaps and volumes

Using ConfigMaps with volumes is the most flexible option. You can reference entire configuration files, as well as make updates to the ConfigMap that will be reflected in running containers. This means you can make changes to entries in a ConfigMap after you’ve deployed a Pod, and those changes be seen in containers and available for running applications. The updates may take a minute or so to be reflected in the running container.

The high-level process for exposing ConfigMap data via a volume looks like this.

1\. Create the ConfigMap\
2\. Create a ConfigMap volume in the Pod template\
3\. Mount the ConfigMap volume into the container\
4\. Entries in the ConfigMap will appear in the container as individual files

![](<../.gitbook/assets/Screen Shot 2022-07-03 at 8.26.25 am.png>)

## Secrets

Secrets are almost identical to ConfigMaps – they hold application configuration data that is injected into containers at run-time. However, Secrets are designed for sensitive data such as passwords, certificates, and OAuth tokens.

### Are Secrets secure?

The quick answer to this question is “no”. But here’s the slightly longer answer...

Despite being designed for sensitive data, Kubernetes does not encrypt Secrets in the cluster store. It merely obscures them as base-64 encoded values that can easily be decoded. Fortunately, it’s possible to configure encryption-at-rest with Encryption- Configuration objects, and most service meshes encrypt network traffic. Despite this, many people opt to use external 3rd-party tools, such as HashiCorp’s Vault, for a more complete and secure secrets management solution.

We’ll focus on the basic secrets management functionality provided natively by Kubernetes as it’s still useful if augmented with 3rd-party tools.

A typical workflow for a Secret is as follows.

1. The Secret is created and persisted to the cluster store as an un-encrypted object
2. A Pod that uses it gets scheduled to a cluster node
3. The Secret is transferred over the network, un-encrypted, to the node
4. The kubelet on the node starts the Pod and its containers
5. The Secret is mounted into the container via an in-memory tmpfs filesystem and decoded from base64 to plain text
6. The application consumes it
7. If/when the Pod is deleted, the Secret is deleted from the node

While it’s possible to encrypt the Secret in the cluster store and leverage a service\
mesh to encrypt it in-flight on the network, it’s always mounted as plain-text in the Pod/container. This is so the app can consume it without having to perform decryption or base64 decoding operations.

Also, use of in-memory tmpfs filesystems mean they’re never persisted to disk on a node.

So, to cut a long story short, no, Secrets aren’t very secure. But, you can take extra steps to make them secure.

They’re also limited to 1MiB (1,048,576 bytes) in size.

An obvious use-case for Secrets is a generic TLS termination proxy for use across your dev, test, and prod environments. You create a standard image, and use a Secret to load the appropriate TLS keys at run-time for each environment.

![](<../.gitbook/assets/Screen Shot 2022-07-03 at 8.29.32 am.png>)

