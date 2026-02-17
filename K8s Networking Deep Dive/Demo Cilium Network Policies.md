In this tutorial, we'll secure a sample application using Cilium Network Policies. We'll progress from a default Kubernetes NetworkPolicy (Layer 3) to a full L7 HTTP policy with header-based access control.

### Demo App Overview

Our demo application runs as a single Pod with two containers listening on ports **5000** and **80**. It exposes two corresponding ClusterIP Services.

```bash
$ kubectl get all
```

```text
NAME                                  READY   STATUS    RESTARTS   AGE
pod/demo-deployment-7ccd685fcc-7z9wf  2/2     Running   0          5m

NAME                   TYPE        CLUSTER-IP       PORT(S)    AGE
service/app-svc-5000   ClusterIP   10.111.51.97     5000/TCP   5m
service/app-svc-80     ClusterIP   10.102.122.72     80/TCP    5m
service/kubernetes     ClusterIP   10.96.0.1         443/TCP  10m
```

Both containers serve the same Flask app. We'll lock down access so only Pods labeled `app=admin` can communicate.

### 1. Default Kubernetes NetworkPolicy

We begin with a basic Kubernetes NetworkPolicy named `demo-netpol`. It selects Pods labeled `app=demo` and allows ingress from Pods labeled `app=admin` on **all ports**.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demo-netpol
spec:
  podSelector:
    matchLabels:
      app: demo
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: admin
```

#### Verifying the Default Policy

1. **Allowed**: Pod with `app=admin` can reach both ports.

   ```bash
   $ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
       --labels app=admin --restart=Never -- \
       curl --connect-timeout 2 app-svc-80
   # Have a great day!

   $ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
       --labels app=admin --restart=Never -- \
       curl --connect-timeout 2 app-svc-5000
   # Have a great day!
   ```

2. **Denied**: Pod *without* the label is blocked.

   ```bash
   $ kubectl run --rm -i --tty client-pod --image=curlimages/curl \
       --restart=Never -- \
       curl --connect-timeout 2 app-svc-80
   # curl: (28) Failed to connect...
   ```

**Before applying Cilium policies, delete the existing Kubernetes NetworkPolicy so that Cilium's default behavior (allow all) is restored.**

```bash
$ kubectl delete networkpolicy demo-netpol
```

### 2. Cilium Layer 3 Policy

Create `cilium-l3.yaml` to reimplement the same L3 selector using Cilium's CRD:

```yaml  theme={null}
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: demo-cilium-l3
spec:
  endpointSelector:
    matchLabels:
      app: demo
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: admin
```

Apply and test:

```bash
$ kubectl apply -f cilium-l3.yaml

# Unlabeled Pod => denied:
$ kubectl run --rm -i --tty client-pod --image=curlimages/curl \
    --restart=Never -- \
    curl --connect-timeout 2 app-svc-80

# Labeled Pod => allowed:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-5000
# Have a great day!
```

### 3. Cilium Layer 4 Policy

Tighten (ограничим) access to only TCP port 80. Update to `cilium-l4.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: demo-cilium-l4
spec:
  endpointSelector:
    matchLabels:
      app: demo
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: admin
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
```

```bash
$ kubectl apply -f cilium-l4.yaml

# Port 80 => allowed:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-80

# Port 5000 => denied:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-5000
# curl: (28) Failed to connect...
```

### 4. Cilium Layer 7 HTTP Policy

Leverage Cilium's L7 HTTP inspection to allow only `GET /healthz` and `GET /api`. Define `cilium-l7.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: demo-cilium-l7
spec:
  endpointSelector:
    matchLabels:
      app: demo
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: admin
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: GET
          path: /healthz
        - method: GET
          path: /api
```

```bash
$ kubectl apply -f cilium-l7.yaml

# Default path => denied:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-80

# /api => allowed:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-80/api

# /healthz => allowed:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-80/healthz
# {"status":"OK"}
```

### 5. Adding an API Key Header

Finally, require an `X-API-KEY` header for the `/api` endpoint. Update to `cilium-l7-header.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: demo-cilium-l7-header
spec:
  endpointSelector:
    matchLabels:
      app: demo
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: admin
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: GET
          path: /healthz
        - method: GET
          path: /api
          headers:
          - name: X-API-KEY
            value: ABC123
```

```bash
$ kubectl apply -f cilium-l7-header.yaml

# Missing header => denied:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl --connect-timeout 2 app-svc-80/api

# With header => allowed:
$ kubectl run --rm -i --tty admin-pod --image=curlimages/curl \
    --labels app=admin --restart=Never -- \
    curl -H "X-API-KEY: ABC123" --connect-timeout 2 app-svc-80/api
# Have a great day!
```

### Policy Progression

| Stage      | Layer | File                    | Description                             |
| ---------- | ----- | ----------------------- | --------------------------------------- |
| Kubernetes | L3    | `demo-netpol`           | Pod selector + ingress from `app=admin` |
| Cilium     | L3    | `cilium-l3.yaml`        | Same selector using Cilium CRD          |
| Cilium     | L4    | `cilium-l4.yaml`        | Restrict to TCP port 80                 |
| Cilium     | L7    | `cilium-l7.yaml`        | Allow only GET `/healthz` & `/api`      |
| Cilium     | L7+H  | `cilium-l7-header.yaml` | Adds `X-API-KEY` header check           |