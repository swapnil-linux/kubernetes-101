# 7. Ingress

In the previous chapter, you saw how Service objects provide stable networking for Pods. You also saw how to expose applications to external consumers via NodePort Services and LoadBalancer Services. However, both of these have limitations.

NodePorts only work on high port numbers (30000-32767) and require knowledge of node names or IPs. LoadBalancer Services fix this but require a 1-to-1 mapping between an internal Service and a cloud load-balancer. This means a cluster with 25 internet-facing apps will need 25 cloud load-balancers, and cloud load-balancers aren’t cheap.

Ingress fixes this by exposing multiple Services through a single cloud load-balancer.

To do this, Ingress creates a single LoadBalancer Service, on port 80 or 443, and uses host-based and path-based routing to send traffic to the correct backend Service.

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 3.19.55 pm.png>)

## Ingress architecture

Ingress is a stable resource in the Kubernetes API. It went GA in Kubernetes 1.19 after being in beta for over 15 releases. During the 3+ years it was in alpha and beta, service meshes increased in popularity and there’s some overlap in functionality. As a result, if you plan to run a service mesh, you may not need Ingress.

Ingress is defined in the networking.k8s.io API sub-group as a v1 object and is based on the usual two constructs.

1\. A controller

2\. An object spec

The object spec defines rules that govern traffic routing and the controller implements them. Ingress operates at layer 7 of the OSI model, also known as the “application layer”. This means it has awareness of HTTP headers and can inspect them and forward traffic based on hostnames and paths.

The below figure shows two different hostnames (URLs) configured to hit the same load-balancer. An Ingress object is watching and uses the hostnames in the HTTP headers to route traffic to the appropriate backend Service. This is an example of the HTTP host- based routing pattern, and it’s almost identical for path-based routing.

![](<../.gitbook/assets/Screen Shot 2022-06-28 at 3.29.07 pm.png>)

For this to work, name resolution needs to point the appropriate DNS names to the public endpoint of the Ingress load-balancer. In this example, you’ll need `shield.mcu.com` and `hydra.mcu.com` to resolve to the public IP of the Ingress load-balancer.

Now that you know the basics, let’s see it in action.
