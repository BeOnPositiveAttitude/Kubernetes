ExternalDNS automates DNS record management for Kubernetes services and ingresses, ensuring applications remain reachable as resources change.

The Kubernetes DNS system enables services and pods to discover one another via in-cluster lookups. When you expose applications to the public internet, managing DNS records manually can become error-prone. ExternalDNS automates this process by synchronizing Kubernetes Services and Ingresses with your DNS provider - AWS Route 53, Cloudflare, Google Cloud DNS, and more.

<img src="image.png" width="700" height="400"><br>

ExternalDNS continuously watches for Kubernetes resource changes. When a Service or Ingress is created, updated, or deleted, it will create, update, or remove the corresponding DNS records, ensuring your applications remain reachable even as IP addresses shift (изменился).

<img src="image-1.png" width="700" height="400"><br>

### Key Features

1. **Dynamic DNS Updates**\
   Reacts in real time to scaling events, rolling updates, or resource deletions - keeping DNS entries accurate (точными, правильными) without manual steps.

2. **Flexibility & Control**
   - Manages DNS for LoadBalancer, NodePort, ClusterIP, and headless Services, as well as Ingress resources.
   - Use annotation-based filters or custom FQDN templates to target specific records.
   - Optionally ignore selected resources using annotation rules.

3. **Broad Provider Compatibility**\
   ExternalDNS integrates with the most popular DNS services, making it ideal for hybrid and multi-cloud deployments.

   | DNS Provider        | Use Case                 | Example Flag              |
   | ------------------- | ------------------------ | ------------------------- |
   | AWS Route 53        | Public zones on AWS      | `--provider=aws`          |
   | Google Cloud DNS    | GCP-managed domains      | `--provider=google`       |
   | Azure DNS           | Azure public DNS zones   | `--provider=azure`        |
   | Cloudflare          | External DNS management  | `--provider=cloudflare`   |
   | DigitalOcean DNS    | DO-managed domains       | `--provider=digitalocean` |
   | NS1, Infoblox, etc. | Enterprise DNS solutions | `--provider=<name>`       |

### Architecture Scenarios

- **LoadBalancer**\
  In cloud environments (AWS, GCP, Azure), ExternalDNS creates DNS A/AAAA-records pointing to provisioned external IPs.

- **NodePort / ClusterIP**\
  Map DNS to node IPs plus NodePorts, or manage ClusterIP entries - even if they're only internally routable.

- **Headless Services**\
  Assign stable DNS names to individual pod IPs (e.g., for Kafka or other stateful sets).

### Installation

Add the ExternalDNS Helm chart and update:

```bash
$ helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
$ helm repo update
```

**Ensure your cloud IAM role or API credentials have permissions to create and modify DNS records. See [ExternalDNS GitHub](https://github.com/kubernetes-sigs/external-dns) for provider-specific requirements.**

Install with Helm, replacing `provider` and provider-specific settings as needed:

```bash
$ helm install external-dns external-dns/external-dns \
    --namespace kube-system \
    --set provider=aws \
    --set aws.zoneType=public
```

**You can also install ExternalDNS by applying a plain Kubernetes Deployment manifest - ideal for GitOps workflows.**

### Deployment Configuration

Below is a sample `Deployment` manifest. Adjust `args` to fit your environment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.13.7
        args:
        - --source=service
        - --source=ingress
        - --provider=aws
        - --registry=txt
        - --txt-owner-id=my-cluster
```

#### General Arguments

- `--source` (service, ingress)
- `--namespace` (limit scope)
- `--provider` (aws, google, azure, cloudflare, etc.)
- `--policy` (sync or create-only)
- `--domain-filter` (restrict to specific domains)

#### Security, Authentication & Advanced Options

- `--registry` (txt, aws-tags)
- `--txt-owner-id` (unique TXT record owner)
- `--annotation-filter` (manage only annotated resources)
- `--fqdn-template` (custom FQDN generation)


### Configuring Application Resources

ExternalDNS discovers resources via annotations. Add these under `metadata` in your Service or Ingress:

```yaml
# Basic Annotations
external-dns.alpha.kubernetes.io/hostname: example.com
external-dns.alpha.kubernetes.io/ttl: "3600"

# Advanced Annotations
external-dns.alpha.kubernetes.io/target: 192.168.0.5
external-dns.alpha.kubernetes.io/scope: global
```

#### Example: LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myservice.example.com
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

When this Service deploys, ExternalDNS will automatically create and maintain the DNS record `myservice.example.com`, updating it if the external IP changes.

### Quiz

What is the purpose of the `--txt-owner-id` flag in ExternalDNS?

- To provide a unique identifier for the ExternalDNS instance.