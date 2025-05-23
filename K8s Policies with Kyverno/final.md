apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: config-true-policy
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-for-labels
    match:
      resources:
        kinds:
        - ConfigMap
    validate:
      message: "ConfigMaps must have label 'updated'"
      pattern:
        metadata:
          labels:
            updated: "true"

apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: security-high-policy
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-for-annotation
    match:
      resources:
        kinds:
        - Secret
    validate:
      message: "Secrets must have annotation 'security'"
      pattern:
        metadata:
          annotations:
            "security": "high"

