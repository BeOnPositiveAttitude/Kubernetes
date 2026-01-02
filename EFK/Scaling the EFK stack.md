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