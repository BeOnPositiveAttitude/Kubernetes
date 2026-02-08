In this guide, you'll learn how to deploy Traefik as an Ingress controller on your Kubernetes cluster. We cover:

1. Manual installation using Kubernetes manifests (Quick Start)
2. Installation with Helm and customizing the service type
3. Deploying a demo application behind Traefik
4. Enabling and viewing Traefik access logs

### 1. Manual Installation (Quick Start)

This section walks you through deploying Traefik using static YAML manifests. We'll configure RBAC, deploy Traefik, and expose it via LoadBalancer services.

#### 1.1 Create RBAC Resources

Traefik needs permission to watch and update Kubernetes resources. First, define a `ClusterRole`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik-role
rules:
- apiGroups: ["*"]
  resources:
  - services
  - secrets
  - endpoints
  - ingresses
  - configmaps
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io", "discovery.k8s.io"]
  resources: ["ingresses", "ingressclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses/status"]
  verbs: ["update"]
```

Bind this role to a ServiceAccount in the `kube-system` namespace:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-account
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-binding
subjects:
  - kind: ServiceAccount
    name: traefik-account
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: traefik-role
  apiGroup: rbac.authorization.k8s.io
```

Ensure your cluster's RBAC is enabled. If you run into `Forbidden` errors, verify that the ServiceAccount and ClusterRoleBinding are created correctly.

[Официальная документация](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-crd/)

#### 1.2 Deploy the Traefik Controller

Create a Deployment for Traefik, specifying the ServiceAccount:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: kube-system
  labels:
    app: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik-account
      containers:
      - name: traefik
        image: traefik:v3.1
        args:
        - --api.insecure=true
        - --providers.kubernetesingress=true
        - --entryPoints.web.address=:80
        - --entryPoints.websecure.address=:443
        ports:
        - name: web
          containerPort: 80
        - name: websecure
          containerPort: 443
        - name: dashboard
          containerPort: 8080
```

The `--api.insecure` flag enables an unsecured dashboard. Do **not** use this in production environments. For secure dashboards, configure TLS and authentication.

#### 1.3 Expose Traefik with LoadBalancer Services

Create a Service manifest (`traefik-svc.yaml`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik-web
  namespace: kube-system
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  selector:
    app: traefik
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  type: LoadBalancer
  ports:
  - name: dashboard
    port: 8080
    targetPort: 8080
  selector:
    app: traefik
```

Apply all resources:

```bash
$ kubectl apply -f traefik-role.yaml \
  -f traefik-account.yaml \
  -f traefik-binding.yaml \
  -f traefik-deployment.yaml \
  -f traefik-svc.yaml
```

Check the LoadBalancer IPs:

```bash
$ kubectl -n kube-system get svc
```

### 2. Helm Installation

Installing Traefik via Helm simplifies upgrades and customization.

#### 2.1 Add the Traefik Helm Repository

```bash
$ helm repo add traefik https://traefik.github.io/charts
$ helm repo update
$ kubectl create namespace traefik
```

#### 2.2 Install with Default Values

```bash
$ helm install traefik traefik/traefik --namespace=traefik
```

Verify resources:

```bash
$ kubectl -n traefik get all
```

### 2.3 Customizing the Service Type

On clusters without a LoadBalancer (e.g., bare-metal), switch to `NodePort`. Create `values.yaml`:

```yaml
  type: NodePort
  ports:
    web:
      nodePort: 32080
    websecure:
      nodePort: 32443

logs:
  access:
    enabled: true
```

Upgrade the release:

```bash
$ helm upgrade traefik traefik/traefik --namespace=traefik --values=values.yaml
```

Confirm the NodePort assignment:

```bash
$ kubectl -n traefik get svc
# NAME      TYPE       CLUSTER-IP      PORT(S)
# traefik   NodePort   10.xx.xx.xx     80:32080/TCP,443:32443/TCP
```

If you change ports in `values.yaml`, ensure your firewall or cloud provider permits traffic on the new NodePorts.

### 3. Demo App Ingress Configuration

Deploy a simple "whoami" service and expose it via Traefik.

#### 3.1 Deploy the `whoami` Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  labels:
    app: whoami
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
      - name: whoami
        image: traefik/whoami
        ports:
        - name: http
          containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  type: ClusterIP
  selector:
    app: whoami
  ports:
  - name: http
    port: 80
    targetPort: 80
```

Apply:

```bash
$ kubectl apply -f whoami-app.yaml
```

#### 3.2 Configure an Ingress Resource

Create `whoami-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-ingress
spec:
  ingressClassName: traefik
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: whoami
            port:
              number: 80
```

Apply and verify:

```bash
$ kubectl apply -f whoami-ingress.yaml
$ kubectl describe ingress whoami-ingress
```

Access the demo app:

```bash
$ curl http://<LoadBalancer-IP>/
# or, on NodePort:
$ curl http://<NodeIP>:32080/
```

### 4. Viewing Traefik Logs

Tail the Traefik pod's logs to inspect both general and access logs:

```bash
$ kubectl -n traefik logs -f deployment/traefik
```

With `logs.access.enabled: true`, each HTTP request is recorded in the logs.