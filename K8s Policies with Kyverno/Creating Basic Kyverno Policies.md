## Understanding Kyverno Policies

Policies in Kyverno are defined as Kubernetes resources, which makes them highly integrable with existing Kubernetes workflows. These policies can perform a variety of functions:

- **Validation**: Ensures specific rules are followed by rejecting or reporting configurations that violate policies.
- **Mutation**: Automatically adjusts resources to meet specific requirements before they are admitted (допущены) to the Kubernetes cluster.
- **Generation**: Creates additional resources based on existing ones according to predefined rules.

Kyverno policies are applied to Kubernetes resources (e.g., Pods, Services, etc.) and are executed by the Kyverno controller when resources are created, updated, or deleted.

## Types of Kyverno Policies

- **Validation Policies**: These policies ensure that certain conditions are met before a resource is allowed in the cluster. For example, a validation policy might require that all images come from a trusted registry.

- **Mutating Policies**: These policies modify incoming resources to match organizational standards or fix common issues automatically. For instance, a mutating policy could automatically add a label to all incoming resources.

- **Generation Policies**: These policies create new resources based on triggers from existing resources. An example might be generating a NetworkPolicy resource for each new Namespace.

### Exercise 0: Disallow root

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-root-user
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Running as root is not allowed."
      pattern:
        spec:
          securityContext:
            runAsNonRoot: true
```

Теперь создание подобного pod-а будет запрещено политикой:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsUser: 0
```

### Exercise 1: Enforce Image Registry

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-registries
spec:
  validationFailureAction: Enforce
  rules:
  - name: validate-registries
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Unknown image registry."
      pattern:
        spec:
          containers:
            - image: "kodekloud/*"
```

Манифест pod-а, который удовлетворяет созданным двум политикам:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: webapp-container
    image: kodekloud/webapp-color:v1
    securityContext:
      runAsUser: 1000  # Non-root user
```

### Exercise 3: Require Labels

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels-on-namespace
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-for-labels
    match:
      resources:
        kinds:
        - Namespace
    validate:
      message: "Namespaces must have labels. Please add labels to the namespace."
      pattern:
        metadata:
          labels:
            app: "?*"
```

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels-for-deployments
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-for-labels
    match:
      resources:
        kinds:
        - Deployment
    validate:
      message: "Deployments must have 'app' and 'team' labels. Please add these labels to the deployment."
      pattern:
        metadata:
          labels:
            app: "?*"
            team: "?*"
```