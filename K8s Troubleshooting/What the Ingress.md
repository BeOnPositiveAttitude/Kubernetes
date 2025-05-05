https://kubernetes.github.io/ingress-nginx/examples/rewrite/

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
  name: rewrite
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: rewrite.bar.com
    http:
      paths:
      - path: /something(/|$)(.*)        # в круглых скобках - capture groups
        pathType: ImplementationSpecific
        backend:
          service:
            name: http-svc
            port:
              number: 80
```

In this ingress definition, any characters captured by `(.*)` will be assigned to the placeholder `$2`, which is then used as a parameter in the `rewrite-target` annotation.

For example, the ingress definition above will result in the following rewrites:

- `rewrite.bar.com/something` rewrites to `rewrite.bar.com/` (обе capture groups будут пустые в данном случае)
- `rewrite.bar.com/something/` rewrites to `rewrite.bar.com/` (символ `/` подходит под первую capture group, но вторая capture group все равно пустая)
- `rewrite.bar.com/something/new` rewrites to `rewrite.bar.com/new`

### Lab

You are provided with an ingress definition file `ingress.yml`.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: "myapp.com"
    http:
      paths:
      - pathType: Prefix
        path: "/blog(/|$)(.*)"
        backend:
          service:
            name: blog-service
            port:
              number: 80
      - pathType: Prefix
        path: "/store(/|$)(.*)"
        backend:
          service:
            name: store-service
            port:
              number: 80
```

**Question 1**

Determine the rewritten path of the following request: `myapp.com/blog/articles/2024/kubernetes-intro`.

**Explanation**

The request matches the path `/blog(/|$)(.)`. The rewrite target `/` and `$2` means the path will be rewritten to the value captured by `(.)`, which is `articles/2024/kubernetes-intro`.

**Answer**

`myapp.com/articles/2024/kubernetes-intro`

**Question 2**

Given the ingress definition provided in `ingress.yml`, what is the rewritten path of the following request: `myapp.com/store`?

**Explanation**

The request matches the path `/store(/|$)(.)`. Since there is no trailing part after `/store`, `(.)` captures an empty string. The rewrite target results in `/`.

**Answer**

`myapp.com/store/`

Пример ingress с увеличенными таймаутами:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "120" #added
    nginx.ingress.kubernetes.io/proxy-send-timeout: "120" #added
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  name: ml-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - backend:
          service:
            name: inference-api
            port:
              number: 80
        path: /predict
        pathType: Prefix
```