In this lesson, you'll learn how Kubernetes implements stable service discovery for your applications. We'll demonstrate two primary mechanisms:

1. **Environment Variables** injected into pods at launch
2. **Cluster DNS** names resolving service endpoints

Throughout this guide, we'll use an `nginx-service` deployed in the `default` namespace as our example.

### Service Overview

First, confirm that the `nginx-service` exists in the `default` namespace:

```bash
$ kubectl -n default get svc nginx-service
```

Expected output:

```
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
nginx-service   ClusterIP   10.103.206.194   <none>        80/TCP    10m
```

### 1. Environment Variable–Based Discovery

When a pod starts, the kubelet injects environment variables for each Service in the same namespace. Let's verify this with a temporary pod:

```bash
$ kubectl run -i --tty --rm test-pod --image=ubuntu --restart=Never -- /bin/bash
```

Inside the pod shell, list variables related to `nginx-service`:

```bash
$ env | grep -i nginx
```

You should see:

```
NGINX_SERVICE_PORT=tcp://10.103.206.194:80
NGINX_SERVICE_PORT_80_TCP_ADDR=10.103.206.194
NGINX_SERVICE_PORT_80_TCP_PORT=80
NGINX_SERVICE_SERVICE_HOST=10.103.206.194
NGINX_SERVICE_SERVICE_PORT=80
```

Use these variables to curl the service:

```bash
$ curl http://$NGINX_SERVICE_SERVICE_HOST:$NGINX_SERVICE_SERVICE_PORT
```

You'll receive the standard NGINX welcome page HTML.

#### 1.1 Limitations Across Namespaces

Environment variables are only injected into pods in the same namespace as the Service.

To see this in action, launch a pod in the `kube-system` namespace:

```bash
$ kubectl -n kube-system run -i --tty --rm test-pod --image=ubuntu --restart=Never -- /bin/bash
$ env | grep -i nginx
```
No output appears, since `nginx-service` resides in `default`.

### 2. Cluster DNS–Based Discovery

Kubernetes also runs a DNS server (CoreDNS or kube-dns) that resolves Service names cluster-wide. Pods automatically get DNS settings in `/etc/resolv.conf`:

```bash
$ cat /etc/resolv.conf
```

Typical output:

```
search kube-system.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

#### 2.1 Verifying DNS Resolution

Install DNS utilities and lookup the Service FQDN:

```bash
$ apt install -y dnsutils
$ nslookup nginx-service.default.svc.cluster.local
```

Expected response:

```
Name:   nginx-service.default.svc.cluster.local
Address: 10.103.206.194
```

You can curl using the full DNS name:

```bash
$ curl http://nginx-service.default.svc.cluster.local
```

#### 2.2 Shortened DNS Names

Since `svc.cluster.local` is in your search domains, you can use a shorter name:

```bash
$ nslookup nginx-service.default
$ curl http://nginx-service.default
```

Both will resolve to `10.103.206.194`.

### Comparison of Discovery Methods

| Method | Scope | Example Usage |
| ----------- | ----------- | ----------- |
| Environment Variables | Same namespace only | `echo $NGINX_SERVICE_SERVICE_HOST` |
| Cluster DNS | Cluster-wide | `curl http://nginx-service.default.svc.cluster.local` |

### Summary

- **Environment Variables**

  Injected per namespace by the kubelet. Simple but limited to in-namespace communication.

- **Cluster DNS**

  Provides cross-namespace, cluster-wide name resolution. Requires CoreDNS or kube-dns running.

### Lab

```yaml
---
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
    protocol: TCP
    port: 3306
    targetPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: website-service
  namespace: website
spec:
  selector:
    role: website
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
```