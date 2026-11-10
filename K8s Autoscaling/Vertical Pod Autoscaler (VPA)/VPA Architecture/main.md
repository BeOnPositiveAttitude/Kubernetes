Welcome. This article explains the Vertical Pod Autoscaler (VPA) architecture: what VPA does, how its components interact, and how it complements (дополняет) horizontal autoscaling.

VPA helps right-size (подбирать размер) individual pods by adjusting their CPU and memory resource requests (and optionally limits) based on observed workload. Horizontal scaling (adding more replicas) and vertical scaling (increasing a pod's resources) solve different problems: VPA prevents poor performance or OOMs caused by under-provisioning and reduces waste (напрасные траты) from oversized requests by continuously recommending or applying better resource requests.

(here)
Think of VPA as an operations manager that observes real workload patterns and adjusts each pod's "role size" (resource requests). VPA does not change a running container in-place - it updates PodSpecs and triggers a pod restart (eviction + recreation) so the new pod starts with the adjusted request values.

![A presentation slide titled "Why Do We Need VPA?" with two rounded callout boxes. The boxes explain that VPA dynamically adjusts pod CPU and memory to meet demand and keeps applications efficient, preventing crashes and reducing waste.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Vertical-Pod-Autoscaler-VPA/VPA-Architecture/vpa-dynamic-cpu-memory-efficiency.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=c65bf17b3f42df1421a4de0aa8b35ad4)

Why use VPA?

* Prevents performance degradation and OOM kills by ensuring pods get sufficient CPU and memory.
* Reduces wasted costs from over-provisioned pods by recommending smaller, accurate resource requests.
* Complements Horizontal Pod Autoscaler (HPA): use HPA to scale the number of replicas; use VPA to right-size each replica.

VPA core components

VPA is implemented as a control loop with three cooperating components. The following table summarizes each component and its responsibilities.

| Component | Responsibility | Inputs |
| - | - | - |
| Recommender | Observes pod CPU and memory usage over time and computes recommended resource requests (and optionally limits). | Metrics APIs (e.g., `metrics-server`), historical usage, OOM events, VPA configuration (target, min/max) |
| Updater | Compares current pod requests to recommendations and evicts pods when it's safe to apply updated requests. | Recommender suggestions, pod lifecycle/eviction safety checks |
| Admission Controller (mutating webhook) | Injects recommended requests into a PodSpec at creation time so new pods start with the desired requests. | Admission requests for pod creation, Recommender targets |

* Recommender: Uses metrics sources and configured bounds to compute suggested CPU/memory requests. It analyzes historical patterns and OOM signals to produce conservative and safe recommendations.
* Updater: Orders and performs evictions only when it determines it is safe, coordinating with higher-level controllers to avoid destabilizing workloads.
* Admission Controller: Ensures replacement pods (or new pods) are created with the recommended requests by mutating the PodSpec at admission time.

Modes of operation

VPA supports three modes that control how recommendations are applied:

| Mode | Behavior | Use case |
| - | - | - |
| `initial` | Sets resource requests when pods are created but does not evict running pods to apply updates. | Provide better defaults for new pods without disrupting running workloads. |
| `auto` | Actively enforces recommendations across the pod lifecycle: mutates new pods at creation and evicts/recreates pods when updated requests are necessary. | Continuous right-sizing in environments where restarts/evictions are acceptable. |
| `off` | Only records and exposes recommendations; does not mutate PodSpecs or evict pods. | Dry-run or analysis mode to observe suggested resource changes without applying them. |

Choose the mode that aligns with your deployment patterns and availability constraints. Note that changes to requests can affect how HPA calculates utilization (HPA commonly uses CPU requests as the denominator), so plan and test accordingly.

VPA changes resource *requests* (and optionally limits) by causing pod restarts (evictions and recreations). Using VPA in `auto` mode can interact with other controllers (for example, HPA) and affect deployment availability. Always test VPA behavior in a staging environment before enabling it in production.

VPA operation walkthrough

A typical lifecycle with VPA looks like this:

1. Create/configure a VPA object for a workload (Deployment, StatefulSet, or a set of pods).
2. Recommender reads current and historical usage metrics and the VPA configuration (targets and bounds), then generates recommended CPU and memory requests.
3. Updater compares recommendations to current pod requests. If an update is needed and eviction is safe, the Updater evicts the pod so a replacement can be created with updated requests.
4. When the controller (for example, the Deployment controller) creates the replacement pod, the VPA Admission Controller intercepts the pod creation and injects the Recommender's recommended requests into the PodSpec.
5. The kube-controller-manager and the relevant controllers create the new pod with the updated requests. The Recommender continues observing usage and the loop repeats as the workload changes.

This flow is shown in the diagram below: user config → Recommender uses metrics → Updater triggers evictions → Admission Controller injects recommendations into new PodSpecs.

![A simplified architecture diagram titled "VPA Walkthrough" showing components of a Vertical Pod Autoscaler: VPA Config, Metrics Server, and a VPA box containing Recommender, Updater, and Admission Controller that provide recommendations to update Pod resources and interact with the Kubernetes controller. Arrows show data flow between a user, the components, and a Pod.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Vertical-Pod-Autoscaler-VPA/VPA-Architecture/vpa-walkthrough-architecture-diagram.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=c54f39dc971babdded4d39ebf1c007e7)

Best practices and considerations

* Start in `off` or `initial` mode to gather recommendations and validate them before enabling `auto`.
* Monitor interactions with HPA: changing requests affects utilization calculations and may change scaling decisions.
* Use min/max bounds in your VPA configuration to prevent recommendations outside acceptable ranges.
* Test VPA in a staging cluster with representative workloads, paying attention to eviction frequency and rollout impacts.
* Ensure your metric source (for example, `metrics-server` or a metrics adapter) provides reliable CPU and memory usage data for accurate recommendations.

Putting it all together

VPA provides continuous right-sizing of pod resource requests to match real workload needs. The Recommender, Updater, and Admission Controller form a control loop that observes usage, computes targets, and applies them by recreating pods with updated requests. Choose the appropriate VPA mode and test interactions with other autoscalers and controllers to ensure application availability and predictable scaling behavior.

Links and References

* [Vertical Pod Autoscaler (VPA) GitHub](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
* [Kubernetes Documentation](https://kubernetes.io/docs/)
* `metrics-server` - [https://github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server)

> [card] [Watch Video](https://learn.kodekloud.com/user/courses/kubernetes-autoscaling/module/0a6c48bd-c431-4b14-b33b-250d02997055/lesson/eb2c4234-8e6b-441d-8aca-fbd37687b40c)


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.