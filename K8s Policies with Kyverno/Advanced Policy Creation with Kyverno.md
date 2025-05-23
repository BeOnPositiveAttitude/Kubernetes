## Understanding Network Policies with Kyverno

Kyverno allows you to define and enforce network policies directly, making it easier to manage and apply these policies across your clusters.

### Example: Restricting Pod Communications

To restrict communication between pods, you can define a Kyverno policy that specifies allowed or denied traffic patterns. Here's a basic example:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-pod-communication
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: default-deny
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "All pod communications are denied by default."
      pattern:
        spec:
          =(containers):
            - =(ports):
                - !exists
```

Kyverno can validate existing resources in the cluster that may have been created before a policy was created. This can be useful when evaluating the potential effects some new policies will have on a cluster prior to changing them to `Enforce` mode. The application of policies to existing resources is referred to as background scanning and is enabled by default unless `spec.background` is set to `false`.

https://kyverno.io/docs/policy-reports/background/

This policy enforces that no pod can communicate with another unless explicitly allowed. It's a "deny all" approach, which is a secure default posture:

- `=(containers)`: Matches all containers in the pod (the `=` prefix means "match all elements in the array")

- `=(ports)`: Within each container, looks at all ports definitions

- `!exists`: The policy requires that ports **DO NOT exist** (the `!` negates the exists check)

In Kyverno, the `=(containers):` syntax is part of a conditional filter used in policies to dynamically match and process resources based on their structure. Let's break it down:

- The `=` symbol indicates that Kyverno should evaluate the expression dynamically (like a variable or a loop).

- `(containers)` refers to a **JMESPath (JSON Matching Expression) query** that extracts the containers array from a Kubernetes resource (e.g., a Pod or Deployment).

- The `:` at the end signifies the start of a loop, meaning Kyverno will process each container in the array individually.

- `=(containers):` is a **JMESPath-based loop** for processing arrays in Kubernetes resources.

https://kyverno.io/docs/policy-types/cluster-policy/validate/#anchors

## Enforcing Resource Quotas with Kyverno

Kyverno can enforce resource quotas by ensuring that every deployed resource specifies limits and requests for CPU and memory.

### Example: Enforcing Default Resource Limits

Here's how you can enforce default resource limits for pods:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: enforce-default-resource-limits
spec:
  rules:
  - name: set-default-resource-limits
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
                memory: "256Mi"
                cpu: "500m"
              requests:
                memory: "128Mi"
                cpu: "250m"
```

This policy ensures that every pod has default resource limits and requests set, promoting fair resource usage across all applications.

## Managing Secrets with Kyverno

Kyverno can enforce policies around secret creation, usage, and access, ensuring that secrets are handled securely within your Kubernetes clusters.

### Example: Restricting Secret Access

To restrict access to secrets, you can create a policy that specifies which namespaces or users can access certain secrets:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-secret-access
spec:
  validationFailureAction: Enforce
  rules:
  - name: limit-secret-access
    match:
      resources:
        kinds:
        - Secret
    validate:
      message: "Access to secrets is restricted."
      deny:
        conditions:
        - key: "{{request.operation}}"
          operator: Equals
          value: "CREATE"
        - key: "{{request.namespace}}"
          operator: NotEquals
          value: "approved-namespace"
```

This policy prevents the creation of secrets outside of the `approved-namespace`, ensuring that sensitive information is tightly controlled.

### Exercise 1

This policy ensures that pods cannot communicate with each other internally by enforcing strict security contexts, disabling host networking, and setting DNS policy to limit internal communications.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-pod-communication
spec:
  rules:
  - name: restrict-internal-communication
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Pods should not be able to communicate with each other internally."
      pattern:
        spec:
          containers:
          - securityContext:
              capabilities:
                drop:
                - ALL
              allowPrivilegeEscalation: false
          hostNetwork: false
          hostPID: false
          hostIPC: false
          dnsPolicy: ClusterFirstWithHostNet
```

### Exercise 2

Implement a validation Kyverno policy named `enforce-default-resource-limits` to enforce that every pod has resource limits of 256Mi and 500m and requests of 128Mi and 250m set for CPU and memory.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: enforce-default-resource-limits
spec:
  validationFailureAction: Enforce
  rules:
  - name: validate-resource-requests-limits
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Resource requests and limits must be set to memory: 128Mi/256Mi and CPU: 250m/500m."
      pattern:
        spec:
          containers:
          - resources:
              limits:
                memory: "256Mi"
                cpu: "500m"
              requests:
                memory: "128Mi"
                cpu: "250m"
```

### Exercise 3

To ensure only authorized and controlled namespace to expose services to external traffic, configure a Kyverno policy named `limit-service-loadbalancer` to only allow LoadBalancer services in the `web-services` namespace.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: limit-service-loadbalancer
spec:
  validationFailureAction: Enforce
  rules:
  - name: restrict-loadbalancer-services
    match:
      resources:
        kinds:
        - Service
    validate:
      message: "LoadBalancer services are only allowed in the web-services namespace."
      pattern:
        metadata:
          namespace: "web-services"
        spec:
          type: "LoadBalancer"
```

По итогу политика запрещает создание сервиса например типа ClusterIP в namespace `default`. Некорректная работа.

Возможно этот вариант более правильный:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: limit-service-loadbalancer
spec:
  validationFailureAction: Enforce
  rules:
  - name: restrict-loadbalancer-services
    match:
      resources:
        kinds:
        - Service
    validate:
      message: "LoadBalancer services are only allowed in the web-services namespace."
      deny:
        conditions:
        - key: "{{request.operation}}"
          operator: Equals
          value: "CREATE"
        - key: "{{request.namespace}}"
          operator: NotEquals
          value: "web-services"
        - key: "{{ request.object.spec.type }}"
          operator: Equals
          value: LoadBalancer
```

### Exercise 4

Create a Kyverno policy named `mandatory-labels` to ensure that all new Pods and Deployments have a `department` label. The `department` label must have a value from the predefined list: `finance`, `engineering`, `marketing`, `sales`, `hr`. The policy should enforce this requirement. You can make use of preconditions rules for this.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: mandatory-labels
spec:
  validationFailureAction: Enforce
  rules:
  - name: mandatory-labels
    match:
      resources:
        kinds:
        - Pod
        - Deployment
    validate:
      message: "Must have department label"
      pattern:
        metadata:
          labels:
            department: "?*"
    preconditions:
      all:
      - key: "{{ request.object.metadata.labels.department }}"
        operator: In
        value: ["finance", "engineering", "marketing", "sales", "hr"]
```

### Exercise 5

Implement a policy `restrict-node-port` that prohibits the use of NodePort services cluster-wide.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-node-port
spec:
  validationFailureAction: Enforce
  rules:
  - name: disallow-nodeport-services
    match:
      resources:
        kinds:
        - Service
    validate:
      message: "NodePort services are not allowed in this cluster."
      pattern:
        metadata:
          spec:
            type: "!NodePort"
```