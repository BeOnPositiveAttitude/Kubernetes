## Restricting Access to Elasticsearch

Elasticsearch is the backend that stores logs and transfers them over to Kibana. It is very important to secure this repository of log information that may be critical for business operations.

### Authentication and Authorization

The first step to implement authentication in Elasticsearch is to add `xpack` security related environment variables to its deployment definition files.

```
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
```

Thereafter (затем), certificates for the user can be generated and converted to a `Secret`. This secret can be mounted to the pod as an environment variable:

```yaml
- name: ELASTIC_PASSWORD
  valueFrom:
    secretKeyRef:
      name: es-credentials
      key: password
```

An alternative to this approach is use of **executable binaries** within the running `elasticsearch` pod. After adding the `xpack` environment variables to the configuration and applying the file, binary utilities such as `elasticsearch-setup-passwords` or `elasticsearch-users` can be used to add a new user.

## Restricting Access to Kibana

Kibana, as the user interface of the EFK stack, requires careful attention (пристального внимания) to access control to protect sensitive data.

### Authentication and Authorization

Implementing authentication and authorization mechanisms is crucial (ключевым) for controlling access to Kibana.

#### Elasticsearch Security Features

Elasticsearch provides built-in security features that can be leveraged to secure Kibana:

```
xpack.security.enabled: true
```

Configure Elasticsearch users and roles to define access permissions, and use these credentials in Kibana configuration file to enforce authentication and authorization. These credentials can be specified as environment variables.

#### Proxy Authentication

Alternatively, use a reverse proxy (such as Nginx or Apache) in front of Kibana to handle authentication. This approach allows for the integration with external authentication providers (LDAP, OAuth, etc.):

```nginx
location / {
  proxy_pass http://kibana:5601;
  auth_basic "Restricted Access";
  auth_basic_user_file /etc/nginx/.htpasswd;
}
```

### Session Management

Configure session management in Kibana to control session timeouts and ensure that users are logged out after periods of inactivity.

We can also use Role-Based Access Control (RBAC) in Kubernetes to secure our cluster by controlling who can access and perform actions within the cluster.

Also, it is important to use stable images when deploying containers in the kubernetes cluster. To further identify and mitigate (для дальнейшего выявления и устранения) potential security vulnerabilities, these images should be scanned.

## Enabling Fluentd Connection with a Restricted Elasticsearch Pod

The `fluentd` configuration file can be edited to ship logs to the secured Elasticsearch URL by utilizing the same credentials.

Few `ssl` related boolean values need to be changed to `true`.

## Kubernetes Network Policies

Kubernetes network policies are essential for controlling the flow of traffic between stack components and ensuring that only authorized components can communicate with each other.

### Defining Network Policies

Create network policies that specifically allow traffic between Elasticsearch, Fluentd, and Kibana, while denying all other unauthorized traffic.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: efk-stack-policy
  namespace: logging
spec:
  podSelector:
    matchLabels:
      app: efk-stack
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: fluentd
    - podSelector:
        matchLabels:
          app: kibana
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: elasticsearch
```

This policy ensures that only Fluentd and Kibana can send traffic to Elasticsearch, and only Elasticsearch can receive traffic from these components, enhancing the security posture (состояние) of your EFK stack.

## Securing Inter-Component Communications

Securing communication between Elasticsearch, Fluentd, and Kibana ensures that data in transit cannot be intercepted or tampered (подделаны) with by unauthorized entities (лицами).

Internet Protocol Security Virtual Private Network (IPSec VPN), a network security protocol, can be used to encrypt traffic between pods in Kubernetes. Other methods are discussed below.

### TLS Encryption

Implementing TLS (Transport Layer Security) encryption is fundamental in protecting the data exchanged between EFK stack components.

#### Elasticsearch

Start by generating TLS certificates for Elasticsearch. You can use tools like `cert-manager` on Kubernetes to automate certificate management.

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: elasticsearch-cert
  namespace: logging
spec:
  secretName: elasticsearch-tls
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  commonName: elasticsearch.logging.svc.cluster.local
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
```

Configure Elasticsearch to use these certificates for HTTPS:

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
  namespace: logging
spec:
  version: 7.9.3
  http:
    tls:
      selfSignedCertificate:
        disabled: true
  nodeSets:
  - name: default
    count: 3
    config:
      http:
        ssl:
          certificate_authorities: ["/usr/share/elasticsearch/config/certs/ca.crt"]
          certificate: "/usr/share/elasticsearch/config/certs/tls.crt"
          key: "/usr/share/elasticsearch/config/certs/tls.key"
```

#### Fluentd and Kibana

Similarly, ensure Fluentd and Kibana are configured to use TLS for secure communication. Reference the official documentation for each component for specific configuration details.

### Mutual TLS Authentication

Beyond encrypting traffic, consider implementing mutual TLS (mTLS) for an added layer of security. mTLS requires both the client and server to authenticate each other, ensuring that only trusted components can communicate with each other.

### Lab

Включить безопасные настройки в ES:

```yaml
env:
- name: discovery.type
  value: single-node
- name: ES_JAVA_OPTS
  value: "-Xms1g -Xmx1g"
- name: xpack.security.enabled
  value: "true"
- name: xpack.security.transport.ssl.enabled
  value: "true"
```

Создать пользователя в ES:

```bash
$ kubectl exec -it elasticsearch-0 -- bin/elasticsearch-users useradd elastic_user -r superuser -p elasticPass123
```

Здесь параметр `-r` означает роль создаваемого пользователя.

Добавить пользователя в Kibana для аутентификации в ES:

```yaml
env:
- name: ELASTICSEARCH_USERNAME
  value: "elastic_user"
- name: ELASTICSEARCH_PASSWORD
  value: "elasticPass123"
```

Network Policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: efk-stack-policy
  namespace: elastic-stack
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
      namespaceSelector:
        matchLabels:
          name: elastic-stack
  egress:
  - to:
    - podSelector: {}
      namespaceSelector:
        matchLabels:
          name: elastic-stack
```

FluentD:

1. Now, navigate to the `/root/fluentd/etc` folder. Scroll down to the `<match **>` section at the end of this configuration. This part pertains to the recipient elasticsearch.

2. Modify the value of `ssl_verify` parameter to `true` from `false`:

   ```
   ssl_verify true
   ```

3. Add the elasticsearch username and password for the `user` and `password` parameters:

   ```
   user elastic_user
   password elasticPass123
   ```

4. Save this configuration and delete the existing fluentd pod.