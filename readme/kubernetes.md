# Kubernetes

Kubernetes is an application orchestrator. For the most part, it orchestrates containerized cloud-native microservices apps. How about that for a sentence full of buzzwords!

## What is an orchestrator

An orchestrator is a system that deploys and manages applications. It can deploy your applications and dynamically respond to changes. For example, Kubernetes can:

• Deploy your application

• Scale it up and down dynamically based on demand

• Self-heal it when things break

• Perform zero-downtime rolling updates and rollbacks&#x20;

• Lots more...

And the best part about Kubernetes... it does all of this without you having to supervise or get involved. Obviously, you have to set things up in the first place, but once you’ve done that, you sit back and let Kubernetes work its magic.

## Where did Kubernetes come from

Let’s start at the beginning...

Amazon Web Services (AWS) changed the world when it brought us modern cloud computing. Since then, everyone else has been playing catch-up.

One of the companies trying to catch-up was Google. Google has its own very good cloud and needs a way to abstract the value of AWS, and make it easier for potential customers to get off AWS and onto their cloud.

Google also has a lot of experience working with containers at scale. For example,\
huge Google applications, such as Search and Gmail, have been running at extreme scale on containers for a lot of years – since way before Docker brought us easy-to-use containers. To orchestrate and manage these containerised apps, Google had a couple of in-house proprietary technologies called Borg and Omega.

Well, Google took the lessons learned from these in-house systems, and created a new platform called Kubernetes that it donated it to the newly formed Cloud Native Computing Foundation (CNCF) in 2014 as an open-source project.

Kubernetes enables two things Google and the rest of the industry needs.

1\. It abstracts underlying infrastructure such as AWS\
2\. It makes it easy to move applications on and off clouds

Since its introduction in 2014, Kubernetes has become the most important cloud-native technology on the planet.

Like many of the modern cloud-native projects, it’s written in Go, it’s built in the open on GitHub, it’s actively discussed on the IRC channels, you can follow it on Twitter (@kubernetesio), and slack.k8s.io is a pretty good slack channel. There are also regular meetups and conferences all over the planet.

## Kubernetes and Docker

Docker and Kubernetes have worked well together since the beginning of Kubernetes. Docker builds applications into container images and can run them as containers. Kubernetes can’t do either of those. Instead, it sits at a higher level and orchestrates things.

Consider the following quick example. You have a Kubernetes cluster with 10 nodes for running your production applications. The first step is for your development teams to use Docker to package their applications as containers. Once this is done you give those containerised apps to Kubernetes to run. Kubernetes makes high-level orchestration decisions such as which nodes should run the containers, but Kubernetes itself cannot start and stop containers. In the past, each Kubernetes cluster node ran a copy of Docker that would start and stop containers. In this model, the Docker build tools are used to package applications as containers, Kubernetes makes scheduling and other orchestration decisions, and the Docker container runtime performs the low-level job of running containers.

From the outside everything looked good. However, on closer inspection, the Docker runtime is bloated and overkill for what Kubernetes needs. As a result, the Kubernetes project began work to make the container runtime layer pluggable so that users could choose the best container runtime for their needs. We’ll get into more detail later in the book, but in 2016 Kubernetes introduced the container runtime interface (CRI) that made this container runtime layer pluggable. Since then, lots of different container runtimes have been developed for Kubernetes. In 2020 Kubernetes deprecated the Docker runtime, which is jargon meaning it will stop working in a future release.

At the time of writing, containerd (pronounced “container dee”) has replaced Docker as the default container runtime in most Kubernetes clusters. However, Containerd is a stripped-down version of Docker that’s optimized for Kubernetes. As such, all container images created by Docker will continue to work on Kubernetes. In fact, both Docker and Kubernetes work with containers that support the Open Containers Initiative (OCI) specification.

![](<../.gitbook/assets/Screen Shot 2022-07-10 at 12.02.25 pm.png>)

While all of this is interesting, it’s low-level stuff that shouldn’t impact your Kubernetes learning experience. For example, no matter which container runtime you use, the regular Kubernetes commands and patterns will all work as normal.

## Kubernetes – what’s in the name

The name “Kubernetes” (koo-ber-net-eez) comes from the Greek word meaning Helmsman – the person who steers a ship. This theme is reflected in the logo, which is the wheel (helm control) of a ship.

![](<../.gitbook/assets/Screen Shot 2022-07-10 at 12.03.25 pm.png>)

Some of the people involved in the creation of Kubernetes wanted to call it Seven of Nine. If you know Star Trek, you’ll know that Seven of Nine is a Borg drone rescued by the crew of the USS Voyager under the command of Captain Kathryn Janeway. Sadly, copyright laws prevented it from being called Seven of Nine. So, the creators gave the logo seven spokes as a subtle reference to Seven of Nine.

One last thing about the name before moving on. You’ll often see it shortened to “K8s” (pronounced “kates”). The number 8 replaces the 8 characters between the “K” and the “s” and is why people sometimes joke that Kubernetes has a girlfriend called Kate.

## A quick analogy...

Consider the process of sending goods via a courier service.

You package the goods in the courier’s standard packaging, slap one of their labels on\
it, and hand it over to the courier. The courier is responsible for everything else. This includes all the complex logistics of which planes and trucks it goes on, which highways to use, and who the drivers should be etc. They also provide services that let you do things like track your package and make delivery changes. The point is, the only thing you have to do is package and label the goods. The courier does everything else.

It’s the same for apps on Kubernetes. You package the app as a container, give it a Kubernetes manifest, and let Kubernetes take care of deploying it and keeping it running. You also get a rich set of tools and APIs that let you introspect (observe and examine) it. It’s a beautiful thing.
