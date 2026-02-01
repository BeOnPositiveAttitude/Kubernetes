In this tutorial, we'll explore how Kubernetes manages Endpoints and Endpoint Slices by deploying a simple Nginx application. You'll learn how to inspect the Endpoints resource, watch automatic updates as you scale Pods, and examine (исследовать) the more scalable Endpoint Slices feature introduced in Kubernetes 1.17.

### 1. Deploy Nginx and Inspect Endpoints

#### 1.1 Verify Deployment and Service

First, create an Nginx Deployment and a ClusterIP Service (assumed already applied). Then confirm they're up and running:

```bash
$ kubectl get deployment
# NAME                READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment    1/1     1            1           5m
```

```bash
$ kubectl get services
# NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
# kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP    40m
# nginx-service   ClusterIP   10.98.220.254    <none>        80/TCP     5m
```

#### 1.2 List Endpoints

Kubernetes automatically creates an Endpoints object that tracks the Pod IPs behind a Service:

```bash
$ kubectl get endpoints
# NAME            ENDPOINTS            AGE
# kubernetes      192.168.121.182:6443 40m
# nginx-service   10.0.0.55:80         5m
```

The `nginx-service` Endpoints resource shows the Pod's IP (`10.0.0.55`) and port (`80`).

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
  - ip: 10.0.0.55
    nodeName: node01
    targetRef:
      kind: Pod
      name: nginx-deployment-7c79c4bf97-z79j4
      namespace: default
  ports:
  - name: nginx
    port: 80
    protocol: TCP
```