### What is Fluentd?

Fluentd is an open-source data collector designed for processing logs and events. It's highly flexible, allowing you to collect data from multiple sources, transform it as needed, and send it to various destinations.

### Deploying Fluentd as a DaemonSet

A DaemonSet ensures that a copy of the pod runs on each node in the cluster. This is perfect for log collection, as we want Fluentd to collect logs from every node.

#### Create a Fluentd Configuration File

First, create a Fluentd configuration file (say `fluentd-config.conf`) that specifies how logs should be collected and forwarded.

```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>
<match **>
  @type elasticsearch
  host elasticsearch.default.svc.cluster.local
  port 9200
  logstash_format true
</match>
```

Here, `source` and `match` are directives. Following is a list of all directives and the respective aspects of logging they relate to:

- `source`: Input sources.
- `match`: Output destinations.
- `filter`: Event processing pipelines.
- `system`: System-wide configuration.
- `label`: Group the output and filter for internal routing.
- `worker`: Limit to the specific workers.
- `@include`: Include other files.

Apart from directives, fluentd also uses various input and output plugins.

Конфиг из лабы:

```
<label @FLUENT_LOG>
  <match fluent.**>
    @type null
    @id ignore_fluent_logs
  </match>
</label>
<source>
  @type tail
  @id in_tail_container_logs
  path "/var/log/containers/*.log"
  pos_file "/var/log/fluentd-containers.log.pos"
  tag "kubernetes.*"
  exclude_path /var/log/containers/fluent*
  read_from_head true
  <parse>
    @type "/^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/"
    time_format "%Y-%m-%dT%H:%M:%S.%NZ"
    unmatched_lines
    expression ^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$
    ignorecase false
    multiline false
  </parse>
</source>
<match **>
  @type elasticsearch
  @id out_es
  @log_level "info"
  include_tag_key true
  host "elasticsearch.elastic-stack.svc.cluster.local"
  port 9200
  path ""
  scheme http
  ssl_verify false
  ssl_version TLSv1_2
  user
  password xxxxxx
  reload_connections false
  reconnect_on_error true
  reload_on_failure true
  log_es_400_reason false
  logstash_prefix "fluentd"
  logstash_dateformat "%Y.%m.%d"
  logstash_format true
  index_name "logstash"
  target_index_key
  type_name "fluentd"
  include_timestamp false
  template_name
  template_file
  template_overwrite false
  sniffer_class_name "Fluent::Plugin::ElasticsearchSimpleSniffer"
  request_timeout 5s
  application_name default
  suppress_type_name true
  enable_ilm false
  ilm_policy_id logstash-policy
  ilm_policy {}
  ilm_policy_overwrite false
  <buffer>
    flush_thread_count 8
    flush_interval 5s
    chunk_limit_size 2M
    queue_limit_length 32
    retry_max_interval 30
    retry_forever true
  </buffer>
</match>
```

#### Define the DaemonSet

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.11-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.default.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: dockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

Манифесты для лабы:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: elastic-stack
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      # deprecated option
      # serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.14.1-debian-elasticsearch7-1.0
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.elastic-stack.svc.cluster.local"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "http"
        - name: FLUENTD_SYSTEMD_CONF
          value: disable
        - name: FLUENT_CONTAINER_TAIL_EXCLUDE_PATH
          value: /var/log/containers/fluent*
        - name: FLUENT_ELASTICSEARCH_SSL_VERIFY
          value: "false"
        - name: FLUENT_CONTAINER_TAIL_PARSER_TYPE
          value: /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/ 
        - name: FLUENT_ELASTICSEARCH_LOGSTASH_PREFIX
          value: "fluentd"
        resources:
          limits:
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: configpath
          mountPath: /fluentd/etc
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: configpath
        hostPath:
          path: /root/fluentd/etc
```

Также понадобятся следующие сущности:

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: elastic-stack
  labels:
    app: fluentd
EOF
```

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
  labels:
    app: fluentd
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - namespaces
  verbs:
  - get
  - list
  - watch
EOF
```

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluentd
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: elastic-stack
EOF
```

#### Deploy the DaemonSet

Apply the DaemonSet definition to your cluster.

```shell
$ kubectl apply -f fluentd-daemonset.yaml
```

### Configuring Fluentd for Kubernetes Logs

Fluentd needs to be configured to collect logs from both Kubernetes nodes and pods. The configuration we defined earlier in `fluentd-config.conf` sets Fluentd to listen for logs and forward them to Elasticsearch.

#### Collecting Node Logs

The DaemonSet configuration mounts the `/var/log` directory from the host into the Fluentd container, allowing Fluentd to access and collect system and application logs from the nodes.

#### Collecting Pod Logs

Similarly, mounting `/var/lib/docker/containers` enables Fluentd to collect logs from Docker containers, including those managed by Kubernetes pods.

#### Forwarding Logs to Elasticsearch

The Fluentd configuration specifies Elasticsearch as the destination for logs. Ensure that Elasticsearch is running and accessible from within your Kubernetes cluster.

```
<match **>
  @type elasticsearch
  host elasticsearch.default.svc.cluster.local
  port 9200
  logstash_format true
</match>
```

The above configuration forwards all collected logs to Elasticsearch, where they can be indexed and made searchable.

This has been made possible because of the use of output plugin `fluent-plugin-elasticsearch` which is used to forward data to Elasticsearch. The `match` section displays the parameters it uses.