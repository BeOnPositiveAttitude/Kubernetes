Welcome back. In this lesson we'll prepare the demo environment for the Vertical Pod Autoscaler (VPA). Before we install and run the VPA components, it's important to understand the foundational piece VPA relies on: Custom Resource Definitions (CRDs). This background clarifies how VPA integrates with the Kubernetes API and persists both configuration and historical metrics.

A Custom Resource Definition (CRD) extends the Kubernetes API by adding new resource types. Kubernetes already understands built-in objects such as Pods, Services, and Deployments. CRDs let you teach Kubernetes new "words" — domain-specific resources — so the cluster can create, store, and manage those objects just like native resources. Practically, a CRD creates new API endpoints on the Kubernetes API server that operators and controllers (such as VPA) use to read and write configuration and runtime state.

Think of CRDs as expanding the cluster's vocabulary so it can represent and persist concepts like Vertical Pod Autoscaler objects.

![A presentation slide titled "Custom Resource Definition (CRD)" stating CRDs let you create custom Kubernetes resources and showing a diagram of a central K8s Cluster box connected by arrows to POD and Services boxes and to a VPA box, with a user/control icon at the left.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Vertical-Pod-Autoscaler-VPA/VPA-Setup-Demo/crd-k8s-cluster-pod-services-vpa.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=bde5358b4ecaa98aa76bbd1f5ba2a77d)

CRDs enable controllers to extend Kubernetes behavior. The VPA uses CRDs to define the VPA objects you create (for example, VPA resources that target specific Deployments or Pods) and to persist runtime data such as historical usage. This lets the VPA recommender produce safer, better-informed resource recommendations.

For the Vertical Pod Autoscaler there are two CRD types to know:

* VerticalPodAutoscaler CRD — the runtime custom resource you create to declare which workloads VPA should watch and manage. It contains VPA settings and the current recommendations derived from recent container CPU and memory observations.
* VerticalPodAutoscalerCheckpoint CRD — used by VPA to persist historical statistics (a checkpoint) about container CPU and memory usage. Checkpoints provide long-term context that helps the recommender produce safer recommendations, especially after transient events (for example, pod restarts or temporary metric gaps).

![A slide titled "Vertical Pod Autoscaler (VPA) CRDs" showing two labeled boxes: "Vertical Pod Autoscaler CRD" and "Vertical Pod Autoscaler Checkpoint CRD." The left box notes monitoring of container CPU and memory, and the right box notes historical container CPU and memory.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Vertical-Pod-Autoscaler-VPA/VPA-Setup-Demo/vpa-crds-monitoring-checkpoint-cpu-memory.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=05262aea6a377b86c155357b1c5bad57)

In simple terms:

* The VPA CRD acts as a coach: it watches current container CPU and memory usage and produces recommendations to adjust resource requests (and optionally limits).
* The VPA Checkpoint CRD acts as a diary: it records historical usage so the recommender has long-term context and can make safer adjustments after transient events.

Together these CRDs let the VPA controller components (recommender, updater, and admission-controller) operate reliably and persistently via the Kubernetes API. With the CRDs installed, VPA becomes a dynamic mechanism to optimize resource requests so workloads get the CPU and memory they need based on both current observations and historical trends.

Table: VPA CRDs at a glance

| CRD Type | Purpose | Typical contents |
| - | - | - |
| VerticalPodAutoscaler | Declarative VPA object that targets workloads and stores current recommendations | `targetRef`, `updatePolicy`, `resourcePolicy`, `status.recommendation` |
| VerticalPodAutoscalerCheckpoint | Persistent historical statistics used by the recommender | Time-series stats for container CPU/memory usage, timestamps, sample aggregates |

Practical checklist — verifying and applying VPA CRDs

* Apply the CRD manifest for your VPA distribution (example placeholder command):
  ```bash theme={null}
  kubectl apply -f vpa-crds.yaml
  ```
  Replace `vpa-crds.yaml` with the actual manifest file or URL you get from the VPA project release.

* Verify the CRDs were created:
  ```bash theme={null}
  kubectl get crd
  ```
  Look for the VPA-related CRD names in the list that `kubectl` returns.

* View created VPA objects (replace the placeholder with the exact CRD name shown by `kubectl get crd`):
  ```bash theme={null}
  kubectl get <CRD-NAME> --all-namespaces
  ```
  For example, the CRD name shown by `kubectl get crd` might be the string you use in place of `<CRD-NAME>`.

VPA controller components and their responsibilities

| Component | Role |
| - | - |
| Recommender | Analyzes current and historical usage to generate resource request recommendations. Uses both VPA and checkpoint CRDs for input and persistence. |
| Updater | Optionally updates live workloads (e.g., evicts pods) to apply new requests safely, based on recommender suggestions and update policies. |
| Admission Controller | Intercepts pod creations and mutates incoming pods to inject VPA-provided recommendations at admission time when configured to do so. |

Before installing VPA controllers, apply the VPA CRDs to your cluster. Controllers rely on those CRD types to read/write VPA objects and checkpoints; installing CRDs first prevents reconciliation errors and missing-resource failures.

Now that the CRD concepts and verification steps are clear, the next step in the demo is to install the VPA controllers (recommender, updater, and admission-controller) and deploy a sample workload so you can observe how recommendations and checkpoints are created and updated.

> [card] [Watch Video](https://learn.kodekloud.com/user/courses/kubernetes-autoscaling/module/0a6c48bd-c431-4b14-b33b-250d02997055/lesson/d1e3c4de-6570-49ea-8de1-2f9e18de0506)

> [card] [Practice Lab](https://learn.kodekloud.com/user/courses/kubernetes-autoscaling/module/0a6c48bd-c431-4b14-b33b-250d02997055/lesson/3732ce77-60fd-4722-a8ff-5135df53b02a)


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.