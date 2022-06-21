# 1. Understanding Kubernetes

Let’s start at the beginning...

Amazon Web Services (AWS) changed the world when it brought us modern cloud computing. Since then, everyone else has been playing catch-up.

One of the companies trying to catch-up was Google. Google has its own very good cloud and needs a way to abstract the value of AWS, and make it easier for potential customers to get off AWS and onto their cloud.

Google also has a lot of experience working with containers at scale. For example,\
huge Google applications, such as Search and Gmail, have been running at extreme scale on containers for a lot of years – since way before Docker brought us easy-to-use containers. To orchestrate and manage these containerised apps, Google had a couple of in-house proprietary technologies called Borg and Omega.

Well, Google took the lessons learned from these in-house systems, and created a new platform called Kubernetes that it donated it to the newly formed Cloud Native Computing Foundation (CNCF) in 2014 as an open-source project.
