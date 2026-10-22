> ## Documentation Index
> Fetch the complete documentation index at: https://notes.kodekloud.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Manual HPA

> Hands-on lab showing manual scaling of a Kubernetes Deployment, observing pod creation and ephemeral hostnames, and explaining effects on application behavior and when to use Services or StatefulSets.

Welcome.

In this lesson we cover a manual Horizontal Pod Autoscaler (HPA) lab: how manually scaling a Deployment changes application behavior and what effects replica adjustments have on running pods and clients.

This lab demonstrates the manual side of horizontal pod autoscaling: you will scale a Deployment's replicas by hand, observe the pods that appear or disappear in the cluster, and note how pod hostnames (and therefore any application behavior that depends on the hostname) can change.

![A presentation slide titled "Lab Overview" showing the objective to demonstrate how scaling a Kubernetes deployment (hostname changes) affects application behavior and to show the impact of increasing replicas on the application's output.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Manual-Scaling/Manual-HPA/lab-overview-kubernetes-scaling-replicas.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=70cc9a74c09ef65c784fad2161d0b427)

## Overview and objective

Goals:

* Manually scale a Deployment (increase and decrease replicas).
* Observe pods being created or removed and examine their unique names.
* Demonstrate how application output can change when pod hostnames change, and why that is generally undesirable for stateful interactions.

Example scenario: scale a simple Flask web application up to three replicas.

## Manual scaling: commands and verification

Use `kubectl scale` to adjust the replica count on a Deployment:

```bash theme={null}
kubectl scale deployment flask-web-app --replicas=3
```

Then verify pods and their status:

```bash theme={null}
kubectl get pods
```

Example output:

```bash theme={null}
NAME                               READY   STATUS    RESTARTS   AGE
flask-web-app-59d5f5df85-4pvbq     1/1     Running   0          2m12s
flask-web-app-59d5f5df85-f4ktj     1/1     Running   0          111s
flask-web-app-59d5f5df85-sc6jq     1/1     Running   0          2m12s
```

Commands summary:

| Command | Purpose |
| - | - |
| `kubectl scale deployment <name> --replicas=<N>` | Set desired replica count for a Deployment |
| `kubectl get pods` | List pods and their current state |
| `kubectl describe deployment <name>` | View Deployment details and ReplicaSet behavior |

Think of a Deployment as a neighborhood plan and pods as houses. When you scale the Deployment, Kubernetes (via the ReplicaSet managed by the Deployment) starts or stops pods to reach the requested replica count. Each pod receives a unique name (and, by default, the pod’s hostname is set to its pod name). That means a hostname for a particular instance can change whenever pods are recreated.

![A slide titled "Lab Overview" showing a Kubernetes cluster and a Deployment containing several pod icons, with arrows from a user icon on the right indicating users accessing those pods. The Kubernetes logo appears at the bottom-left and the image is credited to KodeKloud.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Manual-Scaling/Manual-HPA/lab-overview-kubernetes-deployment-pods-users.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=f2c4a89f07ca287c5f500e43a2c3f250)

## Why pod hostnames matter

* Pod hostnames are tied to pod names by default. When a pod is recreated, its name and hostname change.
* If your application returns or depends on hostname-specific data, client-visible behavior may change after scaling or redeploys (for example, different responses or session binding to a pod hostname).
* Cloud-native best practices: design stateless pods and rely on stable endpoints (Services) rather than individual pod hostnames.

### When to use Service vs StatefulSet

| Requirement | Recommended Kubernetes primitive |
| - | - |
| Stable network identity (DNS) and load-balanced access | Service (ClusterIP / ExternalName / LoadBalancer) |
| Stable, persistent network identity per pod and attached storage | StatefulSet |

## Key takeaways

* Changing a Deployment's replica count is how you increase or decrease the number of running pod instances for an application.
* Every pod has a unique, ephemeral hostname (derived from the pod name by default); these hostnames can change when pods are recreated.
* Because of hostname ephemerality, do not rely on pod hostnames for durable identity or sticky client behavior. Use Services for stable access, externalize state (databases, object storage), or use StatefulSets when you specifically need stable pod identities and persistent volumes.

![A presentation slide titled "Key Takeaways" with three colored panels—Scaling, Hostnames, and Application Behavior—each illustrated by an icon and a short note. It explains that increasing replicas adds pods, each pod gets a unique hostname, and scaling can change application behavior based on those hostnames.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Manual-Scaling/Manual-HPA/key-takeaways-scaling-hostnames-application-behavior.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=a63bc952da785bf54b9fffe2fdf0991a)

Prefer Services for stable access to an application, and prefer stateless pods for easy horizontal scaling. Use StatefulSets only when you require stable pod identities or persistent storage tied to individual pods.

Important: Do not use pod hostnames for durable session affinity, unique user identity, or persistent storage binding. Those requirements need Services, external storage, or StatefulSets to ensure stability across scaling and restarts.

Understanding these behaviors is essential before introducing automated scaling (HPA), because an HPA changes replica counts dynamically based on metrics — the same considerations about ephemeral hostnames and stateful behavior still apply.

Further reading and references:

* [Kubernetes: Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
* [Kubernetes: Services](https://kubernetes.io/docs/concepts/services-networking/service/)
* [Kubernetes: StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

> **[Watch Video](https://learn.kodekloud.com/user/courses/kubernetes-autoscaling/module/66710f67-c094-4a4c-b718-4a031d1ddebe/lesson/4c3caee4-e0bd-4a9e-90ba-ac8e9ea9230f)**

> **[Practice Lab](https://learn.kodekloud.com/user/courses/kubernetes-autoscaling/module/66710f67-c094-4a4c-b718-4a031d1ddebe/lesson/07c8db56-dd00-44c2-9da0-d391e677e204)**


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.