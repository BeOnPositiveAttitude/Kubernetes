apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: always-pull-music
spec:
  rules:
  - name: enforce-image-pull-policy
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


apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: annotate-namespace-owner
spec:
  rules:
  - name: add-owner-annotation
    match:
      resources:
        kinds:
        - Namespace
    mutate:
      patchStrategicMerge:
        metadata:
          annotations:
            owner: "crew"


apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-role-label
spec:
  rules:
  - name: add-role-label-to-pods
    match:
      resources:
        kinds:
        - Pod
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            role: "crew-member"