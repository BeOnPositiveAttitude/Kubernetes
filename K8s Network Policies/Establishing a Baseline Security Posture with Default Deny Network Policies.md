### The Role of Default Deny Network Policies

By default, Kubernetes does not restrict the flow of network traffic between Pods. However, to establish a baseline (базовую) security measure (меру), we can use a 'Default Deny' network policy that denies all network traffic to and from Pods within the namespace unless specified otherwise.

Implementing a Default Deny policy ensures no unauthorized access occurs in any of the Pods, thereby enhancing the security of your Kubernetes cluster.

Here is a simple example of how a Default Deny policy can be implemented for the default namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

The `podSelector` with `{}` implies that the policy applies to all Pods within the default namespace. The absence of `ingress` rules indicates that all inbound network traffic is denied by default.

### Using Default Deny as a Baseline for Fine-Grained Access Control

After implementing a Default Deny policy, we've effectively created a **blacklist** that denies all network traffic by default. This acts as a baseline security measure, safeguarding our Pods from any unnecessary or potentially harmful (вредный) network communication.

This policy serves as a solid foundation upon which we can define fine-grained access controls.

However, this policy by itself, although secure (однако эта политика сама по себе, хотя и безопасна), will most likely break the application as no pods cant connect to any other pod!

To enable the necessary communication paths, such as allowing the middleware to connect to the MySQL database, or the front-end to connect to the middleware, we can create additional network policies. These allow specific types of traffic, effectively creating a **whitelist** atop our **baseline** blacklist.

Политика разрешающая любые соединения между pod-ами.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-allow-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
    - {}
```

Проверить связность: `kubectl exec middleware -- nc -zv mysql-svc 3306`.

Network Policies in Kubernetes are additive, meaning that if there is any Network Policy that allows a certain type of traffic, that traffic will be allowed even if another Network Policy would block it. This design choice is based on the principle of explicitly allowed (явно разрешенного) over implicit deny (неявно запрещенного).

In your example, you have one policy that denies all ingress traffic and one that allows all ingress traffic. Kubernetes will sum these policies, and the result is that all ingress traffic is allowed. The policy to allow traffic is considered an explicit rule that should be followed, even if there's a more general policy that would deny the traffic.

However, it's important to note that this does NOT mean that allow policies always take precedence over deny policies. Rather, all policies are evaluated, and if there is any policy that would allow the traffic, then the traffic is allowed.

This is why when designing your Network Policies, we typically start with a broad deny policy, and then add specific allow policies for just the traffic you want to permit.

Еще один вариант политики, запрещающей все соединения:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress-null
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress: []
```