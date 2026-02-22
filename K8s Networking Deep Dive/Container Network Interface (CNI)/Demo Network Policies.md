In this walkthrough (пошаговом руководстве), we'll explore how to secure Pod-to-Pod and Pod-to-External traffic in Kubernetes using NetworkPolicies. You will learn to:

- Verify the default connectivity behavior
- Apply default-deny rules for egress and ingress
- Permit specific egress/ingress to selected Pods
- Validate the resulting network restrictions

## 1. Verify Default Connectivity

By default, Kubernetes allows all egress and ingress traffic between Pods (even across namespaces) and to the Internet.

### 1.1 Test External Connectivity

Создадим два pod-а:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  labels:
    app: ubuntu
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    command:
    - sleep
    - "7200"
---
apiVersion: v1
kind: Pod
metadata:
  name: pod2
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
```

В контейнер `ubuntu` придется доставить пакеты iputils-ping и curl (чтобы работали команды `ping` и `curl`).

Exec into `pod1` (in the `default` namespace) and ping an external endpoint:

```bash
$ kubectl exec -it pod1 -- ping -c 4 www.google.com
```

You should see successful responses:

```
64 bytes from 142.250.125.103: icmp_seq=1 ttl=111 time=2.05 ms
...
4 packets transmitted, 4 received, 0% packet loss
```

### 1.2 Test Cross-Namespace Connectivity

List Pod IPs in `kube-system` and pick one (e.g. `192.168.121.187`):

```bash
$ kubectl -n kube-system get pods -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}'
```

From `pod1`, ping that IP:

```bash
$ kubectl exec -it pod1 -- ping -c 3 192.168.121.187
```

You should receive replies, confirming open egress/ingress.

By default, no NetworkPolicy is enforced, so all traffic flows freely.

## 2. Apply Default-Deny Egress

To block all outbound traffic from Pods in the `default` namespace, create a **default-deny egress** policy.

```yaml
# deny-egress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}   # selects all Pods in default
  policyTypes:
  - Egress
```

Apply and verify:

```bash
$ kubectl apply -f deny-egress.yaml
$ kubectl describe networkpolicy default-deny-egress
```

You should see `Policy Types: Egress` and no `egress` rules.

### 2.1 Validate Egress Blocking

Attempt to ping Google and a cross-namespace Pod - both should time out:

```bash
$ kubectl exec -it pod1 -- ping -c 2 www.google.com
$ kubectl exec -it pod1 -- ping -c 2 192.168.121.187
```

No responses will be received.

"Закрытый" egress в namespace `default` тем не менее не влияет на прохождение пингов. Т.е. из другого namespace `website` пинги будут проходить до pod-ов в namespace `default`. А вот "закрытый" ingress в namespace `default` уже блокирует прохождение пингов.

```bash
$ POD1_IP=$(kubectl -n default get pod pod1 -ojsonpath='{.status.podIP}')
$ kubectl -n website exec -it website -- ping -c 4 $POD1_IP
PING 10.0.0.44 (10.0.0.44) 56(84) bytes of data.
64 bytes from 10.0.0.44: icmp_seq=1 ttl=62 time=0.796 ms
64 bytes from 10.0.0.44: icmp_seq=2 ttl=62 time=0.510 ms
64 bytes from 10.0.0.44: icmp_seq=3 ttl=62 time=0.722 ms
64 bytes from 10.0.0.44: icmp_seq=4 ttl=62 time=0.485 ms

--- 10.0.0.44 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3030ms
rtt min/avg/max/mdev = 0.485/0.628/0.796/0.133 ms
```

## 3. Apply Default-Deny Ingress

Similarly, deny all inbound traffic to Pods in `default`:

```yaml
# deny-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

Apply the policy:

```bash
$ kubectl apply -f deny-ingress.yaml
```

From a Pod in `kube-system`, try to curl `pod2` (Nginx):

```bash
$ POD_IP=$(kubectl get pod pod2 -o jsonpath='{.status.podIP}')
$ kubectl -n kube-system run --rm -i test-client --image=nginx --restart=Never -- \
  curl --connect-timeout 1 http://$POD_IP
```

You should see a timeout.

**Warning**

Applying default-deny policies without specific allow rules can disrupt critical workloads. Always plan your policies carefully.

## 4. Allow Specific Egress and Ingress

Once Pods are isolated by default, define exceptions:

| Policy Name | Direction | Allowed Peer Pods | Port |
| ----------- | ----------- | ----------- | ----------- |
| `default-deny-egress` | Egress | `app=nginx` | 80 |
| `default-deny-ingress` | Ingress | `app=centos` | 80 |

### 4.1 Permit Egress to NGINX Pods

Update `deny-egress.yaml`:

```yaml
# deny-egress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}   # selects all Pods in default
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: nginx
    ports:
    - protocol: TCP
      port: 80
```

Apply the updated policy:

```bash
$ kubectl apply -f deny-egress.yaml
```

### 4.2 Permit Ingress from Management Pods

Update `deny-ingress.yaml`:

```yaml
# deny-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ubuntu
    ports:
    - protocol: TCP
      port: 80
```

Apply the updated policy:

```bash
$ kubectl apply -f deny-ingress.yaml
```

## 5. Verify Selective Connectivity

1. **Allowed**: From `pod1` => Nginx on port 80

   ```bash
   $ kubectl exec -it pod1 -- curl --connect-timeout 1 http://$POD_IP
   ```

   You should see the Nginx welcome page.

2. **Blocked**: From `pod1` => Nginx on port 8080

   ```bash
   $ kubectl exec -it pod1 -- curl --connect-timeout 1 http://$POD_IP:8080
   ```

   Connections on other ports will time out.

## Recap

- Kubernetes defaults to **allow all** ingress/egress traffic.
- **Default-deny** policies lock down Pods by default.
- Fine-tune communication by defining **egress** and **ingress** rules matching labels, ports, and namespaces.

### Lab

Default deny policy:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-database-network-policy
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-website-network-policy
  namespace: website
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-backup-network-policy
  namespace: backup-system
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
```

Allow `database` pod to get ingress communication from `website` pod on port `3306`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-website-ingress-to-database
  namespace: database
spec:
  podSelector:
    matchLabels:
      role: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          role: website
    - podSelector:
        matchLabels:
          role: website
    ports:
    - protocol: TCP
      port: 3306
```

Allow `database` pod to get ingress communication from `backup` pod on port `3306`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backup-ingress-to-database
  namespace: database
spec:
  podSelector:
    matchLabels:
      role: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          role: backup-system
    - podSelector:
        matchLabels:
          role: backup-system
    ports:
    - protocol: TCP
      port: 3306
```

Allow the backup server egress to the NFS server with IP 10.1.2.3 on port 2049:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-backup-network-policy
  namespace: backup-system
spec:
  podSelector:
    matchLabels:
      role: backup-system 
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 10.1.2.3/32
    ports:
    - port: 2049
      protocol: TCP
```