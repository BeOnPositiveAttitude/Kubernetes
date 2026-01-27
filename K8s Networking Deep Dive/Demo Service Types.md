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
$ kubectl run -i --tty --rm debug --image=curlimages/curl --restart=Never -- sh
```

Inside the debug pod:





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