In this tutorial, we'll explore how Kubernetes manages Endpoints and Endpoint Slices by deploying a simple Nginx application. You'll learn how to inspect the Endpoints resource, watch automatic updates as you scale Pods, and examine (исследовать) the more scalable Endpoint Slices feature introduced in Kubernetes 1.17.

### 1. Deploy Nginx and Inspect Endpoints

#### 1.1 Verify Deployment and Service

First, create an Nginx Deployment and a ClusterIP Service (assumed already applied). Then confirm they're up and running:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 1
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

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    role: nginx
  type: ClusterIP
```

```bash
$ kubectl get deployment
# NAME                READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment    1/1     1            1           5m
```

```bash
$ kubectl get services
# NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
# kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP   132m
# nginx-service   ClusterIP   10.100.159.140   <none>        80/TCP    44s
```

#### 1.2 List Endpoints

Kubernetes automatically creates an Endpoints object that tracks the Pod IPs behind a Service:

```bash
$ kubectl get endpoints
# NAME            ENDPOINTS             AGE
# kubernetes      192.168.121.28:6443   132m
# nginx-service   10.0.1.103:80         21s
```

The `nginx-service` Endpoints resource shows the Pod's IP (`10.0.1.103`) and port (`80`).

#### 1.3 Inspect the Endpoints Resource

View the full Endpoints object:

```bash
$ kubectl get endpoints nginx-service -o yaml
```

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: nginx-service
  namespace: default
subsets:
- addresses:
  - ip: 10.0.1.103
    nodeName: controlplane
    targetRef:
      kind: Pod
      name: nginx-deployment-7d8785d889-jbz7t
      namespace: default
  ports:
  - name: http
    port: 80
    protocol: TCP
```

Alternatively, use describe for a concise (краткий) summary:

```bash
$ kubectl describe endpoints nginx-service
```

```
Name:         nginx-service
Namespace:    default
Subsets:
  Addresses:          10.0.1.103
  NotReadyAddresses:  <none>
  Ports:
    Name  Port  Protocol
    ----  ----  --------
    http  80    TCP
```

### 2. Scaling and Endpoint Updates

Kubernetes updates the Endpoints list automatically when Pods are added or removed.

1. Scale to two replicas:

   ```bash
   $ kubectl scale deployment nginx-deployment --replicas=2
   ```

2. Wait for both Pods to be Running:

   ```bash
   $ kubectl get pods
   ```

3. Describe Endpoints again:

   ```bash
   $ kubectl describe endpoints nginx-service
   ```

   ```
   Name:         nginx-service
   Namespace:    default
   Subsets:
     Addresses:          10.0.0.206,10.0.1.103
     NotReadyAddresses:  <none>
     Ports:
       Name  Port  Protocol
       ----  ----  --------
       http  80    TCP
   ```

4. Delete one Pod and observe the update:

   ```bash
   $ kubectl delete pod nginx-deployment-7c79c4bf97-xd2mw
   $ kubectl describe endpoints nginx-service
   ```

5. Scale back to one replica:

   ```bash
   $ kubectl scale deployment nginx-deployment --replicas=1
   $ kubectl describe endpoints nginx-service
   ```

### 3. Exploring Endpoint Slices

Endpoint Slices improve scalability by splitting Service backends into multiple slice objects.

#### 3.1 List Endpoint Slices

```bash
$ kubectl get endpointslices
# NAME                  ADDRESSTYPE   PORTS   ENDPOINTS        AGE
# kubernetes            IPv4          6443    192.168.121.28   139m
# nginx-service-vx7cs   IPv4          80      10.0.1.103       7m21s
```

#### 3.2 Inspect a Single EndpointSlice

```bash
$ kubectl get endpointslice nginx-service-vx7cs -o yaml
```

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: nginx-service-vx7cs
  namespace: default
  labels:
    kubernetes.io/service-name: nginx-service
    endpointslice.kubernetes.io/managed-by: endpointslice-controller.k8s.io
addressType: IPv4
endpoints:
- addresses:
  - 10.0.1.103
  conditions:
    ready: true
    serving: true
    terminating: false
  nodeName: controlplane
  targetRef:
    kind: Pod
    name: nginx-deployment-7d8785d889-jbz7t
    namespace: default
  ownerReferences:
  - apiVersion: v1
    blockOwnerDeletion: true
    controller: true
    kind: Service
    name: nginx-service
ports:
- name: http
  port: 80
  protocol: TCP
```

Or use:

```bash
$ kubectl describe endpointslice nginx-service-vx7cs
```

```
Name:         nginx-service-vx7cs
AddressType:  IPv4
Ports:
  Name  Port  Protocol
  ----  ----  --------
  http  80    TCP
Endpoints:
  - Addresses:  10.0.1.103
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/nginx-deployment-7d8785d889-jbz7t
    NodeName:   controlplane
    Zone:       <unset>
```

**Warning**

Endpoint Slices are created by default in Kubernetes v1.21+. Make sure your cluster version supports discovery.k8s.io/v1.

#### 3.3 EndpointSlice Updates on Scaling

Scale to two replicas:

```bash
$ kubectl scale deployment nginx-deployment --replicas=2
$ kubectl describe endpointslice nginx-service-vx7cs
```

```
Name:         nginx-service-vx7cs
AddressType:  IPv4
Ports:
  Name  Port  Protocol
  ----  ----  --------
  http  80    TCP
Endpoints:
  - Addresses:  10.0.1.103
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/nginx-deployment-7d8785d889-jbz7t
    NodeName:   controlplane
    Zone:       <unset>
  - Addresses:  10.0.0.27
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/nginx-deployment-7d8785d889-xk9f7
    NodeName:   node01
    Zone:       <unset>
```

Scale back to one replica and verify:

```bash
$ kubectl scale deployment nginx-deployment --replicas=1
$ kubectl describe endpointslice nginx-service-vx7cs
```

```
Name:         nginx-service-vx7cs
AddressType:  IPv4
Ports:
  Name  Port  Protocol
  ----  ----  --------
  http  80    TCP
Endpoints:
  - Addresses:  10.0.1.103
    Conditions:
      Ready:    true
    Hostname:   <unset>
    TargetRef:  Pod/nginx-deployment-7d8785d889-jbz7t
    NodeName:   controlplane
    Zone:       <unset>
```

### 4. Comparison and Conclusion

| Resource Type | Description | Use Case |
| ----------- | ----------- | ----------- |
| Endpoints | Lists Pod IPs and ports for a Service | Simple clusters with few backends |
| EndpointSlice | Splits backends into scalable slices of up to 100 endpoints | Large clusters, high-service cardinality (численность) |

Kubernetes manages both Endpoints and Endpoint Slices automatically. Use Endpoints for small clusters and Endpoint Slices to handle large-scale Service connectivity efficiently.