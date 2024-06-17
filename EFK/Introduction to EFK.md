### The Role of the EFK Stack

The EFK stack combines Elasticsearch, Fluentd, and Kibana to aggregate, store, and visualize logs from multiple sources within a Kubernetes environment.

### Components of the EFK Stack

- **Elasticsearch**: A distributed, RESTful search and analytics engine capable of addressing a growing number of use cases (способная удовлетворить растущее число вариантов использования).

- **Fluentd**: An open-source data collector for unified (унифицированного) logging, which allows you to unify (унифицировать) data collection and consumption (потребление) for better use and understanding of data.

- **Kibana**: A visualization layer that works on top of Elasticsearch, providing a user-friendly interface to visualize data.

### Why Use the EFK Stack?

- **Centralized Logging**: Aggregate logs from all nodes and pods in a cluster, making it easier to monitor and troubleshoot.

- **Scalability**: Elasticsearch scales easily, allowing you to store and query large volumes of data (большие объемы данных) efficiently.

- **Powerful Visualization**: Kibana provides powerful and beautiful visualizations of your log data, helping you to debug and understand application performance.

### Step 1: Deploy Elasticsearch

Elasticsearch - the backend of the EFK stack - is basically a Document-based NoSQL database that runs on port `9200` by default.

Elasticsearch doesn't just store data but also ensures data durability (живучесть) and failure recovery by utilizing replication. To ensure quick availability of data, it utilizes sharding in addition to replication.

In an elasticsearch cluster, its the master node that coordinates actions and manages changes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
spec:
  replicas: 2
  selector:
    matchLabels:
      component: elasticsearch
  template:
    metadata:
      labels:
        component: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.9.3
        ports:
        - containerPort: 9200
```

### Step 2: Deploy Fluentd

Fluentd - the log shipper - utilizes a variety of plugins for filtering and transforming log data. These plugins are defined in the fluentd configuration file, which uses the `.conf` extension.

Fluentd uses memory buffering mechanism to ensure reliable log delivery to Elasticsearch.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <match **>
      @type elasticsearch
      host elasticsearch
      port 9200
      logstash_format true
    </match>
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
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
        image: fluent/fluentd:v1.11.1
        volumeMounts:
        - name: fluentd-config
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
        - name: varlog
          mountPath: /var/log
  volumes:
  - name: fluentd-config
    configMap:
      name: fluentd-config
  - name: varlog
    hostPath:
      path: /var/log
```

### Step 3: Deploy Kibana

Kibana - the visualization wizard - provides extensive data presentation capabilities through graphs and charts and runs on port `5601` by default.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      component: kibana
  template:
    metadata:
      labels:
        component: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.9.3
        ports:
        - containerPort: 5601
```