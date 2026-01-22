In this walkthrough (пошаговом руководстве), we'll explore how to secure Pod-to-Pod and Pod-to-External traffic in Kubernetes using NetworkPolicies. You will learn to:

- Verify the default connectivity behavior
- Apply default-deny rules for egress and ingress
- Permit specific egress/ingress to selected Pods
- Validate the resulting network restrictions

## 1. Verify Default Connectivity

By default, Kubernetes allows all egress and ingress traffic between Pods (even across namespaces) and to the Internet.

### 1.1 Test External Connectivity

Exec into `pod1` (in the `default` namespace) and ping an external endpoint:

```bash
$ kubectl exec -it pod1 --container container1 -- ping -c 4 www.google.com
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
$ kubectl get pods -n kube-system -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}'
```

From `pod1`, ping that IP:

```bash
$ kubectl exec -it pod1 --container container1 -- ping -c 3 192.168.121.187
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

You should see `policyTypes: [Egress]` and no `egress` rules.

### 2.1 Validate Egress Blocking

Attempt to ping Google and a cross-namespace Pod - both should time out:

```bash
$ kubectl exec -it pod1 -- ping -c 2 www.google.com
$ kubectl exec -it pod1 -- ping -c 2 192.168.121.187
```

No responses will be received.

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
$ kubectl run --rm -i test-client --image=centos --namespace=kube-system --restart=Never -- \
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
          app: centos
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