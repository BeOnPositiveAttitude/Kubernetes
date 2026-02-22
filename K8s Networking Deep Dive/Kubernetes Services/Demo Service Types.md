In this guide, you'll learn about the four primary Kubernetes Service types- ClusterIP, NodePort, Headless, and ExternalName - using a sample NGINX deployment. Understanding these service types will help you expose applications both inside and outside your cluster.

### Overview of Service Types

| Service Type | Scope | Use Case | Example Port |
| ----------- | ----------- | ----------- | ----------- |
| ClusterIP | Internal cluster traffic | Internal load-balancing | `80` |
| NodePort | Node's IP + port | External access via node IP and port | `30000` |
| Headless | Pod IPs directly | Direct per-pod connectivity (no LB) | `80` |
| ExternalName | DNS CNAME mapping | Map service to external DNS (no proxy) | N/A |

Before diving in, we've deployed three NGINX pods with the label `role=nginx` in the `default` namespace:

```bash
$ kubectl get pods
# OUTPUT
# NAME                                  READY   STATUS    RESTARTS   AGE
# nginx-deployment-7ff69d756-8qdv8      1/1     Running   0          3m
# nginx-deployment-7ff69d756-hccjn      1/1     Running   0          3m
# nginx-deployment-7ff69d756-stpmz      1/1     Running   0          3m
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      role: nginx
  template:
    metadata:
      labels:
        role: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

### 1. ClusterIP (Default)

ClusterIP is the Kubernetes default service type. It allocates a virtual IP reachable only within the cluster.

#### 1.1 Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: clusterip-svc
  namespace: default
spec:
  type: ClusterIP
  selector:
    role: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
```

```bash
$ kubectl apply -f clusterip-svc.yaml
$ kubectl get svc clusterip-svc
# OUTPUT
# NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
# clusterip-svc    ClusterIP   10.102.157.139   <none>        80/TCP    5m
```

#### 1.2 Testing Internal Access

Launch a temporary pod to test DNS and HTTP:

```bash
$ kubectl run -i --tty --rm debug-pod --image=curlimages/curl --restart=Never -- /bin/sh
```

Inside the debug pod:

```bash
$ nslookup clusterip-svc.default.svc.cluster.local
$ curl http://clusterip-svc.default.svc.cluster.local
# Should return the NGINX welcome page
```

ClusterIP services are only reachable from within the Kubernetes cluster. Use them for internal microservice communication.

### 2. NodePort

NodePort exposes a Service on each Node's IP at a static port, allowing external traffic.

#### 2.1 Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-svc
  namespace: default
spec:
  type: NodePort
  selector:
    role: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30000
```

```bash
$ kubectl apply -f nodeport-svc.yaml
$ kubectl get svc nodeport-svc
# OUTPUT
# NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
# nodeport-svc     NodePort    10.98.229.84     <none>        80:30000/TCP    5m
```

#### 2.2 Access via Node IP

1. Find a node's IP address:

   ```bash
   $ kubectl get node node01 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
   # e.g., 192.168.121.156
   ```

2. From outside the cluster:

   ```bash
   $ curl http://192.168.121.156:30000
   ```

   This should return the NGINX welcome page.

   **Warning**

   Ensure that your cloud provider's firewall or on-premise network allows traffic to the nodePort range (default 30000–32767).

#### 2.3 Internal DNS Resolution

Within the cluster, you can still resolve the service by DNS:

```bash
$ kubectl run -i --tty --rm debug-pod --image=curlimages/curl --restart=Never -- /bin/sh
# Inside the pod:
$ nslookup nodeport-svc.default.svc.cluster.local
$ curl http://nodeport-svc.default.svc.cluster.local
```

### 3. Headless Service

A headless Service omits the cluster IP (`clusterIP: None`) and returns the IPs of individual pods directly.

#### 3.1 Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-svc
  namespace: default
spec:
  clusterIP: None
  selector:
    role: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
```

```bash
$ kubectl apply -f headless-svc.yaml
$ kubectl get svc headless-svc
# OUTPUT
# NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# headless-svc    ClusterIP   None         <none>        80/TCP    5m
```

#### 3.2 DNS and Direct Pod Access

```bash
$ kubectl run -i --tty --rm debug-pod --image=curlimages/curl --restart=Never -- /bin/sh
```

Inside the debug pod:

```bash
$ nslookup headless-svc.default.svc.cluster.local
$ for ip in $(nslookup headless-svc.default.svc.cluster.local | grep Address | awk '{print $2}'); do curl http://$ip; done
```

Headless Services are ideal for stateful applications (e.g., databases) where you need direct pod access for persistent storage or custom load balancing.

### 4. ExternalName

ExternalName maps a Service to an external DNS name by returning a CNAME record.

#### 4.1 Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: externalname-svc
  namespace: default
spec:
  type: ExternalName
  externalName: httpbin.org
```

```bash
$ kubectl apply -f externalname-svc.yaml
$ kubectl get svc externalname-svc
# OUTPUT
# NAME                 TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# externalname-svc     ExternalName   <none>       httpbin.org   <none>    35s
```

#### 4.2 Testing ExternalName

```bash
$ kubectl run -i --tty --rm debug-pod --image=curlimages/curl --restart=Never -- /bin/sh
# Inside the pod:
$ curl http://externalname-svc.default.svc.cluster.local/get
# This request is forwarded to httpbin.org/get
```

ExternalName does not proxy traffic through the cluster - it simply performs a DNS CNAME lookup. Use this to reference external APIs or services.

### Lab

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: database
spec:
  selector:
    role: database
  ports:
  - name: mysql
    port: 3306
    protocol: TCP
    targetPort: 3306
  clusterIP: None
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: website-service-nodeport
  namespace: website
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30000
  selector:
    role: website
  type: NodePort
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: google-analytics
  namespace: website
spec:
  type: ExternalName
  externalName: www.google-analytics.com
```