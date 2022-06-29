# 8. Network Policies

## Network Policies

If you want to control traffic flow at the IP address or port level (OSI layer 3 or 4), then you might consider using Kubernetes NetworkPolicies for particular applications in your cluster. NetworkPolicies are an application-centric construct which allow you to specify how a [pod](https://kubernetes.io/docs/concepts/workloads/pods/) is allowed to communicate with various network "entities" (we use the word "entity" here to avoid overloading the more common terms such as "endpoints" and "services", which have specific Kubernetes connotations) over the network. NetworkPolicies apply to a connection with a pod on one or both ends, and are not relevant to other connections.

The entities that a Pod can communicate with are identified through a combination of the following 3 identifiers:

1. Other pods that are allowed (exception: a pod cannot block access to itself)
2. Namespaces that are allowed
3. IP blocks (exception: traffic to and from the node where a Pod is running is always allowed, regardless of the IP address of the Pod or the node)

When defining a pod or namespace based NetworkPolicy, you use a selector to specify what traffic is allowed to and from the Pod(s) that match the selector.

Meanwhile, when IP based NetworkPolicies are created, we define policies based on IP blocks (CIDR ranges).

![](<../.gitbook/assets/image (5).png>)

### Prerequisites <a href="#prerequisites" id="prerequisites"></a>

Network policies are implemented by the network plugin. To use network policies, you must be using a networking solution or SDN like calico which supports NetworkPolicy. Creating a NetworkPolicy resource without a controller that implements it will have no effect.

## Writing & Applying Network Policies <a href="#writing--applying-network-policies" id="writing--applying-network-policies"></a>

#### Isolation <a href="#isolation" id="isolation"></a>

In a Kubernetes cluster, by default, all pods are non-isolated, meaning all ingress and egress traffic is allowed. Once a network policy is applied and has a matching selector, the pod becomes isolated, meaning the pod will reject all traffic that is not permitted by the aggregate of the network policies applied. The order of the policies is not important; an aggregate of the policies is applied.

#### Network Policy Resource Fields <a href="#network-policy-resource-fields" id="network-policy-resource-fields"></a>

Fields to define when writing network policies:

* `podSelector`  selects a group of pods using a LabelSelector. If empty, it would select all pods in the namespace, so beware when using it.
* &#x20;`policyTypes` lists the type of rules that network policy includes. Value can be `ingress`, `egress`, or both.
  * `ingress` defines the rules that will be applied to the ingress traffic of the selected pod(s). If it is empty, it matches all the ingress traffic. If it is absent, it doesn’t affect ingress traffic.
  * `egress` defines the rules that will be applied to the egress traffic of the selected pod(s). If it is empty, it matches all the egress traffic. If it is absent, it doesn’t affect egress traffic.

#### Ingress & Egress Rules <a href="#egress-rules" id="egress-rules"></a>

An array of rules that would be applied to the traffic coming into the pod (ingress) or/and going out of the pod (egress). It is defined with the following fields.

* `ports`: an array of NetworkPolicyPort (`port`, `endport`, `protocol`)
* `to`: an array of NetworkPolicyPeer (`ipBlock`, `namespaceSelector`, `podSelector`)



\
