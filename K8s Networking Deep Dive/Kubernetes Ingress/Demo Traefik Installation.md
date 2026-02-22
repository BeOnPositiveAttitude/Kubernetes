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
- apiGroups:
  - ""
  resources:
  - configmaps
  - nodes
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  - networking.k8s.io
  resources:
  - ingressclasses
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - update
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - list
  - watch
- apiGroups:
  - traefik.io
  resources:
  - ingressroutes
  - ingressroutetcps
  - ingressrouteudps
  - middlewares
  - middlewaretcps
  - serverstransports
  - serverstransporttcps
  - tlsoptions
  - tlsstores
  - traefikservices
  verbs:
  - get
  - list
  - watch
```

Bind this role to a ServiceAccount in the `kube-system` namespace:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik-binding
subjects:
  - kind: ServiceAccount
    name: traefik
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
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: traefik
    spec:
      automountServiceAccountToken: true
      containers:
      - name: traefik
        image: docker.io/traefik:v3.6.7
        imagePullPolicy: IfNotPresent
        args:
        - --entryPoints.metrics.address=:9100/tcp
        - --entryPoints.traefik.address=:8080/tcp
        - --entryPoints.web.address=:8000/tcp
        - --entryPoints.websecure.address=:8443/tcp
        - --api.insecure=true
        - --api.dashboard=true
        - --ping=true
        - --metrics.prometheus=true
        - --metrics.prometheus.entrypoint=metrics
        - --providers.kubernetescrd
        - --providers.kubernetescrd.allowEmptyServices=true
        - --providers.kubernetesingress
        - --providers.kubernetesingress.allowEmptyServices=true
        - --providers.kubernetesingress.ingressendpoint.publishedservice=kube-system/traefik
        - --entryPoints.websecure.http.tls=true
        - --log.level=INFO
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: USER
          value: traefik
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /ping
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 2
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        readinessProbe:
          failureThreshold: 1
          httpGet:
            path: /ping
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 2
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        ports:
        - name: metrics
          protocol: TCP
          containerPort: 9100
        - name: dashboard
          protocol: TCP
          containerPort: 8080
        - name: web
          protocol: TCP
          containerPort: 8000
        - name: websecure
          protocol: TCP
          containerPort: 8443
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
        volumeMounts:
        - mountPath: /data
          name: data
        - mountPath: /tmp
          name: tmp
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      securityContext:
        runAsGroup: 65532
        runAsNonRoot: true
        runAsUser: 65532
        seccompProfile:
          type: RuntimeDefault
      serviceAccount: traefik
      serviceAccountName: traefik
      volumes:
      - emptyDir: {}
        name: data
      - emptyDir: {}
        name: tmp
```

The `--api.insecure` flag enables an unsecured dashboard. Do **not** use this in production environments. For secure dashboards, configure TLS and authentication.

#### 1.3 Expose Traefik with LoadBalancer Services

Create a Service manifest (`traefik-svc.yaml`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: kube-system
spec:
  type: NodePort
  ports:
  - name: web
    port: 80
    targetPort: web
    nodePort: 31950
    protocol: TCP
  - name: websecure
    port: 443
    targetPort: websecure
    nodePort: 30279
    protocol: TCP
  - name: dashboard
    port: 8080
    targetPort: dashboard
    nodePort: 30280
    protocol: TCP
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

Недостаточно развернуть только указанные объекты. Также необходимо установить кучу CRDs, иначе в логах ingress-контроллера будут сыпаться ошибки.

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
# NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
# traefik      NodePort    10.111.155.6   <none>        80:32080/TCP,443:32443/TCP   3m38s
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
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    app: whoami
  type: ClusterIP
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

With `logs.access.enabled: true` (в файле `values.yaml`), each HTTP request is recorded in the logs. Либо указать аргумент `--accesslog=true` в Deployment.

### Lab

```yaml
apiVersion: v1
kind: Service
metadata:
  name: website-service
  namespace: website
spec:
  ports:
  - name: http
    port: 5000
    protocol: TCP
    targetPort: 5000
  selector:
    app: flaskapp
  type: ClusterIP
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: website-ingress
  namespace: website
spec:
  defaultBackend:
    service:
      name: website-service
      port:
        name: http
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: website-service
            port:
              name: http
```

Трафик приходит сначала на ноду кластера на порт 32080 (здесь публикуется сам ingress-контроллер через свой сервис `traefik` типа NodePort), далее в ingress-правиле идет сопоставление запрошенного location и названия сервиса, трафик перенаправляется на сервис `website-service`. Как видно опция `host` может и не указываться вовсе.