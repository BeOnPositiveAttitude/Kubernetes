## Introduction to Mutating Policies

Mutating policies in Kubernetes are rules that automatically modify resource definitions before they are stored in the cluster's database. These modifications can include adding, changing, or removing configurations to ensure resources comply with organizational standards or enhance their functionality.

### Why Mutating Policies?

1. **Consistency**: They ensure resources are created with consistent configurations, reducing manual errors and deviations.
2. **Automation**: By automatically applying necessary changes, they speed up deployment processes and reduce the need for manual intervention.
3. **Security and Compliance**: Mutating policies can enforce security settings or compliance requirements automatically.

## Six Essential Mutating Policies with Kyverno

Let's explore six key mutating policies that can significantly enhance your Kubernetes resources.

### 1. Default Resource Limits

Ensuring every container has resource limits is crucial for avoiding resource starvation (истощение). This policy automatically adds default CPU and memory limits if they are not specified.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-resources
spec:
  rules:
  - name: set-default-resources
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - (name): "*"
            resources:
              limits:
                +(memory): "256Mi"
                +(cpu): "500m"
              requests:
                +(memory): "128Mi"
                +(cpu): "250m"
```

### 2. Automatically Add Labels

Labels are key-value pairs used for organizing and selecting Kubernetes objects. This policy adds specific labels to every resource for better management.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-labels
spec:
  rules:
  - name: append-labels
    match:
      resources:
        kinds:
        - Deployment
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            environment: dev
            app: critical
```

### 3. Enforce Annotations

Annotations, like labels, are key-value pairs but are used to store non-identifying information. This policy ensures that specific annotations are present on resources.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: enforce-annotations
spec:
  rules:
  - name: add-annotations
    match:
      resources:
        kinds:
        - Service
    mutate:
      patchStrategicMerge:
        metadata:
          annotations:
            "service.beta.kubernetes.io/aws-load-balancer-type": "nlb"
```

### 4. Set Image Pull Policy

The image pull policy determines when an image should be pulled for a container. This policy sets the image pull policy to "Always" to ensure the latest version is used.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: set-image-pull-policy
spec:
  rules:
  - name: enforce-image-pull-policy
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - (name): "*"
            imagePullPolicy: Always
```

### 5. Inject Sidecar Containers

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-logging-sidecar
spec:
  rules:
  - name: add-logging-sidecar
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - name: logging-sidecar
            image: logging-image:latest
            resources:
              limits:
                memory: "64Mi"
                cpu: "250m"
```

### 6. Force Read-Only Root Filesystem

A read-only root filesystem can enhance security by preventing modifications to the filesystem. This policy makes the root filesystem read-only for all containers.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: readonly-root-filesystem
spec:
  rules:
  - name: enforce-readonly-rootfs
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - (name): "*"
            securityContext:
              readOnlyRootFilesystem: true
```

### Exercise 1

Create a Kyverno policy `enforce-deployment-label` to add a specific label `app: critical` on all new Deployments in the `production` namespace.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: enforce-deployment-label
spec:
  rules:
  - name: add-app-label
    match:
      resources:
        kinds:
        - Deployment
        namespaces:
        - production
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            app: "critical"
```