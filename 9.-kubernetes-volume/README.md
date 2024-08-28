# 9. Kubernetes Volume

Kubernetes supports lots of types of storage from lots of different places. For example, block, file, and object storage from a variety of external systems that can be in the cloud or your on-premises datacenters. However, no matter what type of storage, or where it comes from, when it’s exposed on Kubernetes it’s called a _volume_.

![](<../.gitbook/assets/Screen Shot 2022-07-04 at 11.21.21 am.png>)

In the above diagram, on the left are storage providers. They can be traditional enterprise storage arrays from established vendors like EMC and NetApp, or they can be cloud storage services such as AWS Elastic Block Store (EBS) and GCE Persistent Disks (PD). All that’s required is a plugin allowing their storage resources to be surfaced as volumes in Kubernetes.

In the middle of the diagram is the plugin layer. In simple terms, this is the interface that connects external storage with Kubernetes. Modern plugins are be based on the Container Storage Interface (CSI) which is an open standard aimed at providing a clean storage interface for container orchestrators such as Kubernetes.&#x20;

On the right is the Kubernetes persistent volume subsystem. This is a set of API objects that make it easy for applications to consume storage. There are a growing number of storage-related API objects, but the core ones are:

* Persistent Volumes (PV)
* Persistent Volume Claims (PVC)&#x20;
* Storage Classes (SC)

In short PVs map to external storage assets, PVCs are like tickets that authorize applications (Pods) to use them, and SCs make it all automatic and dynamic.

#### A quick example

A Kubernetes cluster is running on AWS and the AWS administrator has created a 25GB EBS volume called “ebs-vol”. The Kubernetes administrator creates a PV called “k8s-vol” that maps back to the “ebs-vol” via the ebs.csi.aws.com CSI plugin. While that might sound complicated, it’s not. The PV is simply a way of representing the external storage asset on the Kubernetes cluster. Finally, the Pod uses a PVC to claim access to the PV and start using it.

![](<../.gitbook/assets/Screen Shot 2022-07-04 at 11.25.04 am.png>)



A few things worth noting.

1. This was a manual process involving the AWS administrator. StorageClasses make this automated.
2. There are rules preventing multiple Pods accessing the same volume (more on this later).
3. You cannot map an external storage volume to multiple PVs. For example, you cannot have a 50GB external volume that has two 25GB Kubernetes PVs each using half of it.

## The Kubernetes persistent volume subsystem

The three core API resources in the persistent volume subsystem are:

* Persistent Volumes (PV)
* Persistent Volume Claims (PVC)&#x20;
* Storage Classes (SC)

Others exist, and storage vendors can extend the Kubernetes API with their own resources to support advanced features.

At a high level, PVs are how external storage assets are represented in Kubernetes. PVCs are like tickets that grant a Pod access to a PV. SCs make it all dynamic.

#### Let’s walk through another example.

Assume you have an external storage system with two tiers of storage:

• Flash/SSD fast storage\
• Mechanical slow archive storage

You expect apps on your Kubernetes cluster to use both, so you create two Storage Classes and map them as follows.

![](<../.gitbook/assets/Screen Shot 2022-07-04 at 11.28.54 am.png>)

With the StorageClass objects in place, applications can create volumes on-the-fly by creating Persistent Volume Claims (PVC) that reference either of the storage classes. Each time this happens, the CSI plugin referenced in the SC instructs the external storage system to create an appropriate storage asset. This is automatically mapped to a PV on Kubernetes and the app uses the PVC to claim it and mount it for use.

Don’t worry if it seems confusing, it’ll make sense when you go through the hands-on later.

Before doing that, you need to learn a bit more about PVCs and SCs.

## Dynamic provisioning with Storage Classes

As the name suggests, storage classes allow you to define different classes/tiers of storage. How you define them is up to you and will depend on the types of storage you have available. For example, if your external storage systems support fast and slow storage, as well as remote replication, you might define these three classes:

• fast-local\
• fast-replicated\
• slow-archive-local

As far as Kubernetes goes, storage classes are resources in the storage.k8s.io/v1 API group. The resource type is StorageClass, and you define them in regular YAML files that you post to the API server for deployment. You can use the sc shortname to refer to them when using `kubectl`.

## Additional volume settings

There are a few other important settings you can configure in a StorageClass. We’ll cover:

• Access mode\
• Reclaim policy

### Access mode

Kubernetes supports three access modes for volumes.

• ReadWriteOnce (RWO)&#x20;

• ReadWriteMany (RWX)&#x20;

• ReadOnlyMany (ROX)

`ReadWriteOnce` defines a PV that can only be bound as R/W by a single PVC. Attempts to bind it from multiple PVCs will fail.

`ReadWriteMany` defines a PV that can be bound as R/W by multiple PVCs. This mode is usually only supported by file and object storage such as NFS. Block storage usually only supports RWO.

`ReadOnlyMany` defines a PV that can be bound as R/O by multiple PVCs.

It’s important to understand that a PV can only be opened in one mode. For example, it’s not possible for a single PV to be bound to a PVC in ROM mode and another PVC in RWM mode.

### Reclaim policy

A volume’s ReclaimPolicy tells Kubernetes how to deal with a PV when its PVC is released. Two policies currently exist:

• Delete&#x20;

• Retain

`Delete` is the most dangerous and is the default for PVs created dynamically via storage classes unless you specify otherwise. It deletes the PV and associated storage resource on the external storage system when the PVC is released. This means all data will be lost! You should obviously use this policy with caution.

`Retain` will keep the associated PV object on the cluster as well as any data stored on the associated external asset. However, other PVCs are prevented from using it in future. The obvious disadvantage is it requires manual clean-up.

Let’s bring everything together with a demo.
