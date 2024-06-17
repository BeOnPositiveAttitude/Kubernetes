### Why Use StatefulSet?

- **Stable Network Identity**: Each pod gets a unique and stable hostname.
- **Ordered, Graceful Deployment and Scaling**: Pods are created and deleted in a predictable order.
- **Persistent Storage**: Each pod can be associated with its storage, which persists across pod rescheduling.

### Creating a StatefulSet

Below is a basic example of a StatefulSet definition for Elasticsearch. Note that you should adjust values such as volumeClaimTemplates according to your environment and needs.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: elastic-stack
spec:
  serviceName: "elasticsearch"
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.1.0
        env:
        - name: discovery.type
          value: single-node
        ports:
        - containerPort: 9200
          name: port1
        - containerPort: 9300
          name: port2
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
      initContainers:
      - name: fix-permissions
        image: busybox
        command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
  - metadata:
      name: es-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
```

Либо можно поменять владельца у самой директории на worker-ноде: `sudo chown -R 1000:root /data/elasticsearch`. Тогда секция `initContainers` не понадобится.

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: elastic-stack
spec:
  ports:
  - name: port1
    port: 9200
    protocol: TCP
    targetPort: 9200
    nodePort: 30200
  - name: port2
    port: 9300
    protocol: TCP
    targetPort: 9300
    nodePort: 30300
  selector:
    app: elasticsearch
  type: NodePort
```

### PV

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-elasticsearch
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/elasticsearch
```