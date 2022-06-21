# Multi-container Pods

Multi-container Pods are a powerful pattern and heavily used in real-world environments.

At a very high-level, every container should have a single clearly defined responsibility. For example, an application that pulls content from a repository and serves it as a web page has two distinct responsibilities:

1\. Pull the content\
2\. Serve the web page

In this example, you should design two containers, one responsible for pulling the content and the other to serve the web page. We call this separation of concerns or separation of responsibilities.

This design approach keeps each container small and simple, encourages re-use, and makes troubleshooting simpler.

However, there are scenarios where it’s a good idea to tightly couple two or more functions. Consider the same example app that pulls content and serves it via a web page. A simple design would have the “sync” container (the one pulling content updates) put content updates in a volume shared with the “web” container. For this to work, both containers need to run in the same Pod so they have access to the same shared volume in the Pod’s shared execution environment.

Co-locating multiple containers in the same Pod allows containers to be designed with a single responsibility but co-operate closely with others.

Kubernetes offers several well-defined multi-container Pod patterns.

* Sidecar pattern
* Adapter pattern
* Ambassador pattern&#x20;
* Init pattern

Each one is an example of the one-container-one-responsibility model.

## Sidecar multi-container Pods

The sidecar pattern is probably the most popular and most generic multi-container pattern. It has a main application container and a sidecar container. It’s the job of the sidecar to augment or perform a secondary task for the main application container.\
The previous example of a main application web container, plus a helper pulling up-to-date content is a classic example of the sidecar pattern – the “sync” container pulling the content from the external repo is the sidecar.

An increasingly important user of the sidecar model is the service mesh. At a high level, service meshes inject sidecar containers into application Pods, and the sidecars do things like encrypt traffic and expose telemetry and metrics.

## Adapter multi-container Pods

The adapter pattern is a specific variation of the sidecar pattern where the helper container takes non-standardized output from the main container and rejigs it into a format required by an external system.

A simple example is NGINX logs being sent to Prometheus. Out-of-the-box, Prometheus doesn’t understand NGINX logs, so a common approach is to put an adapter container into the NGINX Pod that converts NGINX logs into a format accepted by Prometheus.

## Ambassador multi-container Pods

The ambassador pattern is another variation of the sidecar pattern. This time, the helper container brokers connectivity to an external system. For example, the main application container can just dump its output to a port the ambassador container is listening\
on and sit back while the ambassador container does the hard work of getting it to the external system.

It acts a lot like political ambassadors that interface with foreign nations on behalf of a government. In Kubernetes, ambassador containers interface with external systems on behalf of the main app container.

## Init multi-container Pods

The init pattern is not a form of sidecar. It runs a special init container that’s guaranteed to start and complete before your main app container. It’s also guaranteed to only run once.

As the name suggests, it’s job in life is to run tasks and initialise the environment for the main application container. For example, a main app container may need permissions
