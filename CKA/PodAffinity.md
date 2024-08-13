That Pod should be preferred to be only scheduled on nodes where pods with label `level=restricted` are running.

For the topologyKey use `kubernetes.io/hostname`.

There are no taints on any nodes which means no tolerations are needed.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    level: hobby
  name: hobby-project
spec:
  containers:
  - image: nginx:alpine
    name: c
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: level
              operator: In
              values:
              - restricted
          topologyKey: kubernetes.io/hostname
```

We're now doing the same thing on node `controlplane`.

For this we delete the existing pod: `kubectl delete pod restricted --force --grace-period 0`.

And we go ahead and create it again but it runs on `controlplane`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    level: restricted
  name: restricted
spec:
  nodeName: controlplane
  containers:
  - image: nginx:alpine
    name: c
```

Next we delete and recreate our Pod with the affinity:

```bash
kubectl -f /root/hobby.yaml delete --force --grace-period 0
kubectl -f /root/hobby.yaml apply
```

We should see that the pod is now scheduled on the `controlplane` node, just like the `restricted` pod:

```bash
kubectl get pod -owide --show-labels
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE           NOMINATED NODE   READINESS GATES   LABELS
hobby-project   1/1     Running   0          12s   192.168.0.5   controlplane   <none>           <none>            level=hobby
restricted      1/1     Running   0          62s   192.168.0.4   controlplane   <none>           <none>            level=restricted
```