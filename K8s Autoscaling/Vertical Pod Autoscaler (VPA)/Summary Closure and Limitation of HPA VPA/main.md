This article summarizes the key differences, strengths (сильные стороны, преимущества), and limitations of the Horizontal Pod Autoscaler (HPA) and the Vertical Pod Autoscaler (VPA). Use this guidance to choose the right autoscaling strategy for your workloads and to understand practical caveats (нюансы, оговорки, предостережения) when combining autoscalers.

### Overview - HPA vs VPA (high-level)

- HPA scales the number of pod replicas (horizontal scaling). It adds or removes instances of the same pod spec (на основе одной и той же спецификации pod-а) to meet traffic demand.
- VPA adjusts pod CPU and memory requests (and optionally limits) (vertical scaling). It provides recommendations or directly changes resource requests, which may cause pod restarts to apply new values.

HPA usually fits stateless services that scale by adding replicas. VPA is better for stateful, resource-constrained (с ограниченными ресурсами), or single-replica workloads where per-pod resource increases are required.

<img src="image.png" width="700" height="400"><br>

### HPA vs VPA - quick comparison

| Aspect | HPA | VPA |
| ------ | --- | --- |
| Primary action | Scale replicas horizontally | Adjust CPU/memory requests vertically |
| Typical use case | Stateless, load-driven services | Stateful or single-replica services, tuning requests |
| Metrics used | CPU (native) + memory/custom/external via Metrics API and adapters | CPU and memory usage (historical + live); not driven by custom metrics |
| Pod restarts | No (scales without changing pod spec) | May evict/recreate pods when applying new requests |
| Controller scope | Any pods managed by controllers | Only updates controller-managed pods (Deployments, StatefulSets, DaemonSets, ReplicaSets) |

- load-driven services - сервисы, масштабируемые в зависимости от нагрузки

### Key technical details and gotchas (подводные камни, подвохи)

#### Metrics support

- HPA:
  - Natively supports CPU (via the metrics-server).
  - Can use memory and custom/external metrics via the Kubernetes Metrics API and adapters (for example, Prometheus Adapter or KEDA).
  - Use HPA v2+ for multiple metric types (CPU, memory, object/external/custom metrics).
- VPA:
  - Focuses on CPU and memory recommendations and enforcement.
  - Uses historical and current resource usage to recommend or set requests.
  - VPA does not consume custom metrics to drive resizing.

#### How VPA applies changes

- VPA supports different update modes:

  | Mode | Behavior |
  | ---- | -------- |
  | `Off` | Only supplies recommendations; does not change pod specs. |
  | `Initial` | Applies recommendations only at pod creation time via the admission controller; existing pods are not evicted. |
  | `Recreate` | Evicts pods so controllers can recreate them with updated requests; VPA does not perform in-place live updates. |
  | `Auto` | VPA will evict and recreate pods automatically to apply new resource requests. |

- The VPA Admission Controller can inject recommended resource requests at pod creation time so new pods start with the recommended values.
- Because VPA adjusts pod resource requests by evicting and recreating pods, it can cause service disruption for workloads sensitive to restarts.

#### Controller-managed pods only

- VPA will only update pods that are managed by a controller (Deployments, StatefulSets, DaemonSets, ReplicaSets). Standalone/unmanaged Pods are not supported.

#### Interaction and potential conflicts between HPA and VPA

- HPA commonly computes CPU utilization relative to the pod's CPU request. If VPA changes those requests while HPA is using CPU-based scaling, you can get feedback loops (циклы обратной связи), oscillations, or unpredictable scaling.
- Recommended patterns to avoid conflicts:
  - Use VPA in `Off` or `Initial` mode to set reasonable (разумные, обоснованные) requests, then let HPA handle replica scaling.
  - Or, run HPA on custom or external metrics (not CPU/memory) while VPA manages CPU/memory requests.
  - If both must run on CPU/memory, test extensively (всесторонне, широко) in staging to observe interactions and tune policies.
- Always validate combined HPA+VPA behavior in a representative environment.

Avoid running HPA on CPU/memory while VPA is in an active update mode without careful testing - concurrent (одновременные) changes to pod requests can create unstable or unpredictable autoscaling behavior.

### Operational considerations

#### Out-of-memory and cluster capacity

- VPA can reduce OOM events by increasing resource requests to match observed usage.
- If VPA increases requests across many pods simultaneously, scheduling capacity may be exhausted (исчерпана) and pods can become `Pending`.
- Use a Cluster Autoscaler or other cluster-scaling solution to provision additional nodes when VPA-driven increases are expected. Still, verify behavior at production-like scale.

#### Overlapping (перекрытие) VPAs

- Multiple VPA objects selecting the same pods will conflict. Ensure a single VPA controls a given set of pods or that selectors do not overlap.

#### Where VPA is most appropriate

- VPA is best for workloads where horizontal scaling is impractical (непрактично, нецелесообразно): single-instance stateful services, databases, or apps with large per-pod state.
- For typical stateless web services, HPA (or KEDA for event-driven scaling) is usually the preferred approach.
- For complex stateful platforms, operators or custom controllers are often used instead of, or in addition to, VPA.

<img src="image-1.png" width="700" height="400"><br>

### Practical recommendations

- Prefer HPA for stateless workloads that scale horizontally with variable traffic.
- Use VPA for resource-constrained or stateful workloads where increasing per-pod resources makes sense.
- If you need both vertical tuning and horizontal autoscaling:
  - Use VPA in `Off` or `Initial` mode to establish recommended requests, then use HPA to scale replicas based on traffic or external metrics.
  - If HPA must scale on custom/external metrics, integrate via the Kubernetes Metrics API and adapters (for example, Prometheus Adapter, KEDA, or other external metrics providers).
- Always test autoscaling behavior in a staging environment that matches production load patterns and cluster size. Monitor for pod evictions, pending pods, and scheduler limitations.

As of 2025, HPA remains widely used for simple, stateless deployments. VPA is less common (менее распространённый) for general-purpose (общего назначения) deployments but is valuable (представляет ценность) for specialized workloads (for example, databases) where operators or custom controllers often complement or replace VPA functionality.

<img src="image-2.png" width="700" height="400"><br>

#### Short checklist - choosing and combining autoscalers

| Question | Guidance |
| -------- | -------- |
| Is the workload stateless and horizontally scalable? | Prefer HPA (scale replicas). |
| Is the workload stateful or single-replica? | Consider VPA for better per-pod sizing. |
| Will HPA use CPU/memory metrics? | Avoid if VPA actively mutates requests; prefer custom/external metrics instead. |
| Do you expect VPA to increase requests cluster-wide? | Plan for cluster autoscaling and test capacity. |
| Are there multiple VPAs targeting the same pods? | Ensure selectors don't overlap; keep one VPA per pod set. |

- cluster-wide - в масштабах всего кластера

### Final summary

- Choose the tool based on workload characteristics: HPA for horizontal scaling of stateless apps; VPA for vertical resizing of resource-constrained or stateful apps.
- Be aware (будьте внимательны, учитывайте особенности) of VPA's pod restart behavior and its controller-only scope.
- Avoid direct conflicts by separating the metrics driving HPA and VPA (на основе которых работают HPA и VPA), or run VPA in recommendation/initial modes.
- Test thoroughly (тщательно) and consider cluster autoscaling when VPA increases pod resource requests.

Autoscaling is about balancing performance and cost. Validate autoscalers together in realistic environments and choose the approach that meets availability, performance, and cost goals for your workload.

Thanks for reading.