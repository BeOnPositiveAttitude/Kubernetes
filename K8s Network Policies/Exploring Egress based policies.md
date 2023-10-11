So far in this course, we've predominantly (преимущественно) focused on ingress network policies that control incoming traffic to our pods. But, as we all know, communication is a two-way street, and just as it's important to control who or what can access our pods, it's equally critical to regulate where our pods can send data. This is where egress network policies come into play.

You might wonder (удивиться), if we have already defined a default deny and specific ingress policies, why would we need to define egress policies? After all, haven't we already set a solid defense against unwarranted inbound traffic?

While that's true, there's another side to the security equation (уравнение). Egress policies add another layer of defense by ensuring our pods don't interact with services they aren't supposed to. For instance, you might not want your `frontend` pod to have direct access to a `database` pod or an external API. With egress policies, you can effectively control outbound traffic and prevent accidental (случайные) data leaks or exposures (раскрытие).

### A Comparative Look at Egress Vs. Ingress Network Policies

At first glance (на первый взгляд), egress network policies might look similar to ingress ones, but a key difference lies in their respective fields. For example, consider the following egress network policy for our `frontend` pod:

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: frontend-egress
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: middleware
```

In the above YAML snippet, instead of the `ingress:` field we used before, we have `egress:` to control outbound traffic. Likewise (так же), under the `policyTypes:` field, we specify `Egress` instead of `Ingress`. Except for these changes, the rest of the structure closely mirrors the ingress policy we've been using thus far.

### Scenario 1: Default Deny All Egress Traffic
For creating a default deny all egress policy, we specify an empty `egress: []` array.

### Scenario 2: Egress to Specific Pods
If you need to allow egress to specific pods, you would need to include a `podSelector` under `egress`. The snippet might look like this:

```yaml
egress:
- to:
  - podSelector:
      matchLabels:
        role: database
```

In the above snippet, egress is allowed to all pods labeled with `role: database`.

### Scenario 3: Egress to Specific Ports
To allow egress traffic to specific ports, you can specify `port` under `egress`. The snippet might look like this:

```yaml
egress:
- to:
  - podSelector:
      matchLabels:
        role: database
  ports:
  - protocol: TCP
    port: 3306
```

In this snippet, egress traffic is allowed to all pods labeled `role: database`` on TCP port 3306.

Пример из лабы. Разрешить исходящие соединения для всех pod-ов в namespace `default` по порту 53 TCP/UDP.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-on-p53
spec:
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

Пример из лабы. Запретить все исходящие соединения:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: genin-no-egress
  namespace: genin
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
```

Пример из лабы.

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: hokage-allow
  namespace: default
spec:
  podSelector:
    matchLabels:
      rank: hokage
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          rank: genin
      namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: genin
    - podSelector:
        matchLabels:
          rank: jonin
      namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: jonin
```

Пример из лабы:

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: jonin-to-genin
  namespace: jonin
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: genin
      podSelector:
        matchLabels:
          rank: genin
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: charms-and-students
  namespace: charms
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          hogwarts: admitted
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: charms-no-egress
  namespace: charms
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: charms
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-allow-all
  namespace: default
spec:
  podSelector:
    matchLabels:
      i-am: dumbledore
  policyTypes:
  - Egress
  - Ingress
  egress:
  - {}
  ingress:
  - {}
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: potions-rules
  namespace: potions
spec:
  podSelector: {}
  policyTypes:
  - Egress
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          class: potions
  egress:
  - to:
    - podSelector:
        matchLabels:
          class: potions
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: potions-port-rule
  namespace: potions
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: darkarts
    ports:
    - protocol: TCP
      port: 80
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: darkarts-magic
  namespace: darkarts
spec:
  podSelector: {}
  policyTypes:
  - Egress
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          i-am: dumbledore
      namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: default
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```