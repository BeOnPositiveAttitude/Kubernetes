In this tutorial, we'll secure a sample application using Cilium Network Policies. We'll progress from a default Kubernetes NetworkPolicy (Layer 3) to a full L7 HTTP policy with header-based access control.

### Demo App Overview

Our demo application runs as a single Pod with two containers listening on ports **5000** and **80**. It exposes two corresponding ClusterIP Services.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: app-1
        image: wbassler/flask-app-demo:v0.1
        command: [ "flask" ]
        args: [ "run", "-p", "80", "-h", "0.0.0.0" ]
        ports:
        - containerPort: 80
      - name: app-2
        image: wbassler/flask-app-demo:v0.1
        command: [ "flask" ]
        args: [ "run", "-p", "5000", "-h", "0.0.0.0" ]
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: app-svc-80
  namespace: default
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: demo
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: app-svc-5000
  namespace: default
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 5000
  selector:
    app: demo
  type: ClusterIP
```

```bash
$ kubectl get all
```

```text
NAME                                   READY   STATUS    RESTARTS   AGE
pod/demo-deployment-7f74498dfd-w8tv2   2/2     Running   0          4m44s

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kubernetes     ClusterIP   10.96.0.1        <none>        443/TCP    79m
service/app-svc-80     ClusterIP   10.100.186.130   <none>        80/TCP     40s
service/app-svc-5000   ClusterIP   10.97.118.255    <none>        80/TCP     40s

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/demo-deployment   1/1     1            1           7m
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
  policyTypes:
  - Ingress
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
   # curl: (28) Connection timed out after 2002 milliseconds
   ```

**Before applying Cilium policies, delete the existing Kubernetes NetworkPolicy so that Cilium's default behavior (allow all) is restored.**

```bash
$ kubectl delete networkpolicy demo-netpol
```

### 2. Cilium Layer 3 Policy

Create `cilium-l3.yaml` to reimplement the same L3 selector using Cilium's CRD:

```yaml
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
          - 'X-API-KEY: ABC123'
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

### Lab

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-website-ingress-to-database-cnp
  namespace: database
spec:
  endpointSelector:
    matchLabels:
      app: database
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: website
    toPorts:
    - ports:
      - port: "3306"
        protocol: TCP
```

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: allow-backup-to-backup-server-cnp
  namespace: backup-system
spec:
  endpointSelector:
    matchLabels:
      app: backup-system
  egress:
  - toCIDR:
    - 10.1.2.3/32
    toPorts:
    - ports:
      - port: "2049"
        protocol: TCP
```

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-backup-ingress-to-database-cnp
  namespace: database
spec:
  endpointSelector:
    matchLabels:
      app: database
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: backup-system
    toPorts:
    - ports:
      - port: "3306"
        protocol: TCP
```

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: allow-ingress-to-website-api
spec:
  endpointSelector:
    matchLabels:
      app: website
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: integration
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: POST
          path: /api
          headers:
          - 'X-API-KEY: integrationKey123'
```