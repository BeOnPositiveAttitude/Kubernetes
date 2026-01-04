## Elasticsearch Scaling

Elasticsearch, the heart of the EFK stack, stores and allows (предоставляет) for the searching of log data. Scaling Elasticsearch is crucial for maintaining performance as log volume grows.

### Horizontal Scaling

Horizontal scaling involves adding more nodes to the Elasticsearch cluster to distribute the load and data across more resources.

#### Adding Nodes

To add nodes, you can adjust the replica count of your Elasticsearch deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
spec:
  replicas: 3 # Increase the number of replicas as needed
```

#### Sharding

Elasticsearch uses sharding to distribute data across nodes. Increasing the number of shards can improve performance but requires careful planning to avoid over-sharding.

```json
PUT /<index>/_settings
{
  "index" : {
    "number_of_shards" : 5 # Adjust based on your needs
  }
}
```

### Vertical Scaling

While horizontal scaling is preferred, sometimes increasing the resources (CPU and memory) of existing nodes can provide a temporary boost (повышение производительности).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
spec:
  template:
    spec:
      containers:
      - name: elasticsearch
        resources:
          requests:
            memory: "4Gi" # Increase as needed
            cpu: "2" # Increase as needed
```

## Fluentd Scaling

Fluentd collects and forwards logs to Elasticsearch. Scaling Fluentd is essential for preventing log loss or delays.

### Horizontal Scaling

Increase the number of Fluentd instances to handle more log sources or higher log volumes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd
spec:
  replicas: 3 # Increase the number of replicas as needed
```

### Buffer Tuning

Adjust Fluentd's buffer settings to optimize performance and resource usage, and further control data throughput (а также для дальнейшего контроля пропускной способности). This involves tuning the buffer size and the flush (сброс) interval.

```
<buffer>
  @type memory
  flush_interval 5s # Adjust based on throughput and latency requirements
  chunk_limit_size 5MB # Adjust based on available memory
</buffer>
```

## Autoscaling with Kubernetes

Kubernetes offers features like the Horizontal Pod Autoscaler (HPA) that automatically scale the number of pods in a deployment based on observed CPU utilization or other metrics.

### Autoscaling Elasticsearch

To autoscale Elasticsearch, you can use HPA to adjust the number of pods based on CPU or memory usage. However, CPU utilization is a more commonly used metric.

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: es-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: elasticsearch
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 97
```

### Autoscaling Fluentd

Similarly, Fluentd can be autoscaled based on metrics like CPU to ensure it scales with the log volume.

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: fluentd-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fluentd
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Although beneficial (несмотря на свою полезность), auto-scaling thresholds should be carefully picked (тщательно выбирать) so that frequent (частые) and unnecessary scaling operations are avoided.

### Lab

Создать индекс:

```bash
$ curl -X PUT "http://localhost:30200/myindex" -H 'Content-Type: application/json' -d '
{
  "settings": {
    "number_of_shards": 5
  }
}'
```

Let's migrate our data from the old index to this new index. Reindex data from the old index of the form `fluentd-*` to the newly created `myindex`.

```bash
$ curl -X POST "http://localhost:30200/_reindex" -H 'Content-Type: application/json' -d '
{
  "source": {
    "index": "fluentd-2026.01.03"
  },
  "dest": {
    "index": "myindex"
  }
}'
```

```bash
$ kubectl -n elastic-stack get svc elasticsearch -ojsonpath='{.spec.clusterIP}' | xargs -I {} curl -X POST "http://{}:9200/_reindex" -H 'Content-Type: application/json' -d '
{
  "source": {
    "index": "fluentd-2026.01.02"
  },
  "dest": {
    "index": "myindex"
  }
}'
```

ReplicaSet FluentD:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: fluentd-replicaset
  namespace: elastic-stack
  labels:
    app: fluentd
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.14.1-debian-elasticsearch7-1.0
        env:
        - name:  FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.elastic-stack.svc.cluster.local"
        - name:  FLUENT_ELASTICSEARCH_PORT
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
        - name:  FLUENT_ELASTICSEARCH_LOGSTASH_PREFIX
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

Опция metrics-server: `--kubelet-insecure-tls`.

HPA:

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: elasticsearch-autoscaler
  namespace: elastic-stack
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: elasticsearch
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 80
```

Initially, the CPU utilization value for the `elasticsearch-0` pod will be higher, hence, the HPA spins up extra pods.

You can view this in the description of the Horizontal Pods Autoscaler:

```bash
$ kubectl describe hpa elasticsearch-autoscaler
```

However, as the CPU utilization percentage for the elasticsearch pod comes down below the target of 80%, the HPA removes the extra elasticsearch pod.

The Horizontal Pod Autoscaler (HPA) may not immediately scale down the number of replicas, even if the current resource utilization is below the target value. This behavior is intended (предназначено) to prevent rapid (быстрое) and unnecessary scaling that could lead to instability (нестабильности) in the cluster. The HPA uses a stabilization window (окно стабилизации) to observe (для наблюдения) the resource utilization and ensure that scaling decisions are based on sustained (устойчивых) metrics, rather than temporary spikes (временные всплески).

Do not worry if the extra elasticsearch pods are not in the running state.