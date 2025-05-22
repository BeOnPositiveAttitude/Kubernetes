## Why Kyverno CLI?

### Simplifying Policy Testing

Kyverno CLI offers a simplified way to test policies against Kubernetes resources without applying them to a live cluster. This approach helps identify potential issues or misconfigurations before they can impact the cluster.

### Fast Feedback Loop

By testing policies locally, developers and administrators can quickly iterate over policy definitions, receiving immediate feedback. This accelerates the development and refinement (уточнение, улучшение) of policies.

### Integration into CI/CD Pipelines

Kyverno CLI can be integrated into Continuous Integration/Continuous Deployment (CI/CD) pipelines, automating policy compliance checks as part of the deployment process. This ensures that only compliant resources are deployed to the cluster.

## Installing Kyverno CLI

Kyverno CLI can be installed on Linux, macOS, and Windows platforms. Below are the steps for each platform.

### Linux

https://kyverno.io/docs/kyverno-cli/install/#manual-binary-installation

```shell
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.12.0/kyverno-cli_v1.12.0_linux_x86_64.tar.gz
tar -xvf kyverno-cli_v1.12.0_linux_x86_64.tar.gz
sudo cp kyverno /usr/local/bin/
```

### macOS

```shell
brew install kyverno
```

### Windows

Windows users can download the latest version from the [Kyverno GitHub releases](https://github.com/kyverno/kyverno/releases) page and add it to their system path.

## Testing Policies with Kyverno CLI

Once installed, you can start testing your policies against Kubernetes resources. Here's how to validate, mutate, and generate configurations using Kyverno CLI.

### Validate Policies

Validation ensures that your Kubernetes resources meet the specified criteria. To validate a resource against a policy, use the following command:

```shell
kyverno apply /path/to/policy.yaml --resource /path/to/resource.yaml
```

Можно добавить параметр `-t` для вывода результата в виде таблицы.

This command will output whether the resource passes the policy checks.

### Mutate Policies

Mutation policies automatically modify resource configurations. To test how a policy mutates a resource, use:

```shell
kyverno apply /path/to/policy.yaml --resource /path/to/resource.yaml
```

This will output the mutated resource, allowing you to review the changes.

### Generate Policies

Kyverno can also generate additional resources based on existing ones. To test a generate policy, use:

```shell
kyverno apply /path/to/policy.yaml --resource /path/to/resource.yaml
```

If the policy is designed to generate new resources, they will be included in the command's output.

## Practical Example: Testing a Network Policy

Let's put this into practice with a simple example. Assume we have a policy that requires all pods to have a specific label, `environment: production`. We want to test this policy against a pod definition to ensure compliance.

1. Create the Policy (`require-label.yaml`):

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-label
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-for-label
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "The label 'environment: production' is required."
      pattern:
        metadata:
          labels:
            environment: production
```

2. Create a Pod Definition (`pod.yaml`):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-container
    image: nginx
```

3. Test the Policy:

```shell
kyverno apply require-label.yaml --resource pod.yaml
```

This command will indicate whether the pod meets the policy requirements.

By following these steps, you can effectively test Kubernetes policies with Kyverno CLI, ensuring that your cluster configurations are compliant and secure before deployment.

### Exercise 1

Your management now requires that all pods run as non-root users. Before applying this policy to the cluster, they want to test it. Create a mutation policy named `non-root` and test it using the Kyverno CLI with the pod file located at `pod-label.yaml`.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: non-root
spec:
  rules:
  - name: enforce-non-root
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        spec:
          securityContext:
            runAsNonRoot: true
          containers:
          - (name): "*"
            securityContext:
              runAsNonRoot: true
              runAsUser: 1000
```