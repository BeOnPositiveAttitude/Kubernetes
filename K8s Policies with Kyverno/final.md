```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: config-true-policy
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-configmap-label
    match:
      resources:
        kinds:
        - ConfigMap
    validate:
      message: "ConfigMaps must have the label 'updated: true'"
      pattern:
        metadata:
          labels:
            updated: "true"
```

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: security-high-policy
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-secret-annotation
    match:
      resources:
        kinds:
        - Secret
    validate:
      message: "Secrets must have the annotation 'security: high'"
      pattern:
        metadata:
          annotations:
            security: "high"
```

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default-limits
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
                memory: "256Mi"
                cpu: "400m"
              requests:
                memory: "128Mi"
                cpu: "200m"
```


```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inventory-weapons-policy
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-deployment-label
    match:
      resources:
        kinds:
        - Deployment
    validate:
      message: "Deployments must have the label 'inventory: weapons'"
      pattern:
        metadata:
          labels:
            inventory: "weapons"
```

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: always-pull-music
spec:
  rules:
  - name: set-image-pull-policy
    match:
      resources:
        kinds:
        - Pod
        namespaceSelector:
          matchLabels:
            name: music
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - (name): "*"
            imagePullPolicy: Always
```