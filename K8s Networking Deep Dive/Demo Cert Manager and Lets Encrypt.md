In this tutorial, you'll learn how to install Cert-Manager on Kubernetes and obtain an SSL certificate from Let's Encrypt to secure a Traefik Ingress. We'll walk through:

1. Installing Cert-Manager with Helm
2. Reviewing the sample "whoami" app and existing Ingress
3. Creating a Let's Encrypt **staging** Issuer
4. Applying the Issuer and validating resources
5. Updating the Ingress to request TLS
6. Verifying the ACME challenge and certificate issuance
7. Creating a Let's Encrypt **production** Issuer and switching over

### 1. Install Cert-Manager

First, ensure you have Helm installed and a Kubernetes context pointing at your control plane.

```bash
# Add the Jetstack Helm repository
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update

# Create a namespace for Cert-Manager
$ kubectl create namespace cert-manager

# Install Cert-Manager and register its CRDs
$ helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --set crds.enabled=true
```

Wait until all pods in the `cert-manager` namespace are in the `Running` state:

```bash
$ kubectl -n cert-manager get pods
```

**Make sure your cluster meets the [Cert-Manager prerequisites](https://cert-manager.io/docs/installation/).**

### 2. Review the Test App and Ingress

We have a simple "whoami" deployment in the `default` namespace, fronted by Traefik:

```bash
$ kubectl -n default get all
```

Example output:

```text
NAME                          READY   STATUS    RESTARTS   AGE
pod/whoami-66b7d97547-tmjgk   1/1     Running   0          83s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3h43m
service/whoami       ClusterIP   10.99.30.1   <none>        80/TCP    83s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/whoami   1/1     1            1           83s

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/whoami-66b7d97547   1         1         1       83s
```

Check the existing Ingress:

```bash
$ kubectl -n default get ingress whoami-ingress
```

```text
NAME             CLASS    HOSTS   ADDRESS   PORTS   AGE
whoami-ingress   traefik  *       <none>    80      5m
```

Describe it:

```bash
$ kubectl -n default describe ingress whoami-ingress
```

### 3. Create a Let's Encrypt Staging Issuer

To prevent hitting rate limits, start with the staging environment. Save this as `staging-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
  namespace: default
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email:  your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          name: whoami-ingress
```

Объект типа `Issuer` указывает к какому CA обращаться за выпуском сертификата.

Автоматически создастся секрет с именем `letsencrypt-staging`, который будет содержать приватный ключ.

Apply and inspect:

```bash
$ kubectl apply -f staging-issuer.yaml
$ kubectl describe issuer letsencrypt-staging
$ kubectl get secrets
```

You should see `letsencrypt-staging` in the secret list.

### 4. Update the Ingress for TLS

Modify `whoami-ingress.yaml` to include the Cert-Manager annotation and a TLS block:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami-ingress
  namespace: default
  annotations:
    cert-manager.io/issuer: letsencrypt-staging
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - test-example.com
    secretName: web-ssl
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: whoami
            port:
              name: web
```

Apply the updated Ingress:

```bash
$ kubectl apply -f whoami-ingress.yaml
```

Автоматически создастся секрет с именем `web-ssl-cjk6t`, который тоже будет содержать приватный ключ.

**Ensure DNS for `test-example.com` points to your Traefik load balancer before requesting a certificate.**

### 5. Verify the ACME Challenge and Certificate Issuance

Describe the Ingress again to confirm ACME resources:

```bash
kubectl describe ingress whoami-ingress
```

Look for:

- A `cm-acme-http-solver-…` backend under the ACME challenge path
- An event `CreateCertificate` indicating `web-ssl` was requested

```text
Events:
  Type    Reason            Age   From                        Message
  ----    ------            ----  ----                        -------
  Normal  CreateCertificate  10s   cert-manager-ingress-shim  Successfully created Certificate "web-ssl"
```

Смотреть сертификат:

```bash
$ kubectl -n website describe certificate web-ssl
```

### 6. Create a Let's Encrypt Production Issuer

Once staging is validated, switch to the production environment. Create `prod-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-production
  namespace: default
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email:  your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - http01:
        ingress:
          name: whoami-ingress
```

Apply and verify:

```bash
$ kubectl apply -f prod-issuer.yaml
$ kubectl describe issuer letsencrypt-production
```

### 7. Switch Ingress to Production Issuer

Update the Ingress annotation to use the production Issuer:

```bash
$ kubectl annotate ingress whoami-ingress \
    cert-manager.io/issuer=letsencrypt-production \
    --overwrite
```

Describe the Ingress to confirm renewal:

```bash
$ kubectl describe ingress whoami-ingress
```

In the events, you should see:

```text
Normal  RenewCertificate  12s  cert-manager-ingress-shim  Successfully renewed Certificate "web-ssl"
```

Your Traefik Ingress is now secured with a Let's Encrypt production certificate.

## Issuer Configuration Summary

| Issuer Name | Environment | ACME Server URL | Secret Name |
| ----------- | ----------- | --------------- | ----------- |
| letsencrypt-staging| Staging | https://acme-staging-v02.api.letsencrypt.org/directory | letsencrypt-staging |
| letsencrypt-production | Production | https://acme-v02.api.letsencrypt.org/directory | letsencrypt-production |

### Lab

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
  namespace: website
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email:  kodekloud-user@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          name: website-ingress
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: website-ingress
  namespace: website
  annotations:
    cert-manager.io/issuer: letsencrypt-staging
spec:
  tls:
  - hosts:
    - companyx-website.com
    secretName: web-ssl
  defaultBackend:
    service:
      name: website-service-nodeport
      port:
        name: http
  rules:
  - host: companyx-website.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: website-service-nodeport
            port:
              name: http
```

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-production
  namespace: website
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email:  kodekloud-user@gmail.com
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - http01:
        ingress:
          name: website-ingress
```