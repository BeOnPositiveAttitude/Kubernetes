> ## Documentation Index
> Fetch the complete documentation index at: https://notes.kodekloud.com/llms.txt
> Use this file to discover all available pages before exploring further.

# What Is HPA

> Describes Kubernetes Horizontal Pod Autoscaler that automatically adjusts pod replicas based on resource, custom, and external metrics while enforcing min/max and stabilization behaviors.

Welcome. In this lesson we explain the Kubernetes Horizontal Pod Autoscaler (HPA), why it matters, and how it works in practice.

At a high level, the HPA automatically adjusts the number of pod replicas for a workload (for example, a Deployment, ReplicaSet, StatefulSet, or any controller that supports the `scale` subresource) based on observed metrics. To make this concrete, consider a factory analogy.

Imagine a factory with a steady team handling predictable, day-to-day production. When demand is steady, the current workforce is sufficient. But during a sudden surge—seasonal demand or a flash sale—the existing team can’t keep up. The factory tracks metrics such as order volume, stock levels, and custom order requirements. When metrics indicate extra capacity is needed, the factory brings in more workers; when demand falls, it scales down more conservatively to avoid thrashing.

This is exactly what the Horizontal Pod Autoscaler does for applications: it monitors relevant metrics and adjusts pod replicas up or down to meet demand.

![A presentation slide titled "Why Do We Need HPA?" showing that a factory tracks three metrics: order volume, stock levels, and custom order requirements, each represented by a colored circular icon.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Horizontal-Pod-Autoscaler-HPA/What-Is-HPA/why-need-hpa-factory-metrics.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=98af4913482f612297082b950553c829)

## How HPA works (overview)

* HPA periodically queries metrics via Kubernetes metrics APIs (resource, custom, and external metrics) and any configured metrics providers or adapters.
* For each configured metric it computes a desired replica count. When multiple metrics are used, HPA uses the largest desired replica value to satisfy the most constrained metric.
* HPA enforces `minReplicas` and `maxReplicas` boundaries on the target workload.
* HPA supports:
  * Resource metrics (CPU, memory via Metrics Server or another provider)
  * Custom pod metrics (application-level metrics via adapters)
  * External metrics (from external systems)

![A slide titled "Why Do We Need HPA?" showing a diagram where a metrics dashboard feeds an HPA component that adjusts the number of pods/workforce. Icons depict pods, a group of people, and a factory.](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Horizontal-Pod-Autoscaler-HPA/What-Is-HPA/why-hpa-metrics-scale-pods.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=62c728d8dde731df86ab4c242569ba55)

## Conceptual scaling algorithm

1. HPA reads the current value of each configured metric and compares it to the metric target.
2. For each metric, it computes a desired replica count (for example, proportionally scaling based on current vs target values).
3. If multiple metrics are present, HPA chooses the maximum desired count produced by those metrics.
4. It updates the workload’s replica count while respecting `minReplicas`, `maxReplicas`, stabilization windows, and scaling policies to avoid rapid fluctuations.

Practical tips:

HPA requires access to metric APIs. For built-in resource metrics like CPU and memory, install a Metrics Server (or another compatible provider) in the cluster. For custom or external metrics, configure the corresponding metrics adapter/provider.

## Metric types — quick reference

| Metric type | Kubernetes API | Use case | Example |
| - | - | - | - |
| Resource metrics | `metrics.k8s.io` (via Metrics Server) | Container CPU and memory utilization | `resource: { name: cpu, target: { type: Utilization, averageUtilization: 50 } }` |
| Custom pod metrics | Custom Metrics API | App-level metrics per pod (e.g., requests/sec) | `requests_per_second` reported by an adapter |
| External metrics | External Metrics API | Metrics external to cluster (e.g., queue length) | Queue depth from a message broker |

## Example: autoscaling/v2 HPA manifest

Below is a minimal `HorizontalPodAutoscaler` manifest (API `autoscaling/v2`) that targets CPU utilization and constrains replicas between 2 and 10:

```yaml theme={null}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: example-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

Notes on the example:

* `behavior` provides rate-limiting and stabilization controls to avoid rapid scale-in/scale-out cycles.
* Use `autoscaling/v2` when you need multi-metric support and advanced behavior configuration.

HPA responsiveness depends on metric availability and scraping frequency. Ensure your metrics provider is properly configured, and be cautious when exposing custom metrics—misconfiguration can lead to unexpected scaling or resource exhaustion.

![A slide-style infographic titled "Horizontal Pod Autoscaler (HPA)" showing a central HPA box with arrows to features: "Observes metrics", "Adds pods", "Balances thresholds", and "Tracks multiple metrics."](https://mintcdn.com/kodekloud-c4ac6d9a/Xy-QQj1elzzjSGkz/images/Kubernetes-Autoscaling/Horizontal-Pod-Autoscaler-HPA/What-Is-HPA/horizontal-pod-autoscaler-hpa-infographic.jpg?fit=max\&auto=format\&n=Xy-QQj1elzzjSGkz\&q=85\&s=1030f36e728cb12baa8a2a0d98837568)

## Summary

* The Horizontal Pod Autoscaler dynamically scales pod replicas to meet metric-driven targets (CPU, memory, custom, external).
* HPA collects metrics, computes desired replicas per metric, uses the highest desired value, and then updates replicas within configured min/max boundaries.
* For production use, combine proper metrics collection, sensible `minReplicas`/`maxReplicas`, and `behavior` policies for stability.

## Links and references

* Kubernetes HPA documentation: [https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
* Metrics Server: [https://github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server)
* Custom Metrics Adapter examples: [https://github.com/kubernetes-sigs/custom-metrics-apiserver](https://github.com/kubernetes-sigs/custom-metrics-apiserver)

> **[Watch Video](https://learn.kodekloud.com/user/courses/kubernetes-autoscaling/module/245fe895-fa01-4adf-b796-ce7f28666043/lesson/272ed778-7f30-4abc-9c4d-5c7ebac166e3)**


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.