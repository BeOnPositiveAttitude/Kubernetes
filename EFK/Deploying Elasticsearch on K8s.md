### Setting Up a StatefulSet for Elasticsearch

StatefulSets are ideal for stateful applications like Elasticsearch. They provide stable, unique network identifiers and persistent storage for each pod.

#### Why Use StatefulSet?

- **Stable Network Identity**: Each pod gets a unique and stable hostname.
- **Ordered, Graceful Deployment and Scaling**: Pods are created and deleted in a predictable order.
- **Persistent Storage**: Each pod can be associated with its storage, which persists across pod rescheduling.

#### Creating a StatefulSet

Below is a basic example of a StatefulSet definition for Elasticsearch. Note that you should adjust values such as `volumeClaimTemplates` according to your environment and needs.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
spec:
  serviceName: "elasticsearch"
  replicas: 3
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
        image: docker.elastic.co/elasticsearch/elasticsearch:7.9.3
        ports:
        - containerPort: 9200
          name: es-http
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
          storage: 10Gi
```

This YAML file defines a StatefulSet named `elasticsearch` with three replicas. It specifies the use of the Elasticsearch 7.9.3 Docker image and a persistent volume claim for data storage.

Конфигурация для лабы:

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
      initContainers:
      - name: fix-permissions
        image: busybox
        command: ["sh", "-c", "chown -R 1000:root /usr/share/elasticsearch/data"]
        securityContext:     # необязательно указывать
          privileged: true   # необязательно указывать
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
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
  volumeClaimTemplates:
  - metadata:
      name: es-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
```

По умолчанию volume `es-data` монтируется с владельцем `root:root`, а elasticsearch запускается под пользователем с UID 1000 и не имеет прав на запись в каталог `/usr/share/elasticsearch/data`. Проверить права на каталог можно переопределив entrypoint.

Соответственно для решения проблемы можно применить initContainer для смены владельца каталога либо можно поменять владельца у самой директории на worker-ноде: `sudo chown -R 1000:root /data/elasticsearch`. Тогда секция `initContainers` не понадобится.

### Configuring Persistent Volumes for Data Storage

Persistent Volumes (PVs) and Persistent Volume Claims (PVCs) are critical in managing storage in Kubernetes.

#### Understanding PVs and PVCs

- **Persistent Volume (PV)**: Represents a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes.
- **Persistent Volume Claim (PVC)**: A request for storage by a user. It specifies size, and access modes, and can be linked to specific PVs.

#### Example: Persistent Volume Claim

The `volumeClaimTemplates` section in the StatefulSet YAML file automatically creates a PVC for each pod in the StatefulSet. Here's what happens behind the scenes:

```yaml
volumeClaimTemplates:
- metadata:
    name: es-data
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: 10Gi
```

This configuration requests a 10Gi volume with `ReadWriteOnce` access mode for each Elasticsearch pod. The Kubernetes cluster automatically provisions this storage if dynamic provisioning is set up or binds the PVC to a manually created PV.

Конфигурация для лабы:

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

### Using Services for Network Access

Services in Kubernetes provide a way to expose an application running on a set of Pods as a network service.

#### Why Services?

- **Stable IP Addresses**: Services provide stable IP addresses for pods.
- **Load Balancing**: Services can load-balance traffic to multiple pods.
- **Service Discovery**: Services allow other applications to discover and communicate with your Elasticsearch cluster through a stable endpoint.

#### Creating a Service for Elasticsearch

Here's an example of a Service definition for Elasticsearch. This service exposes the Elasticsearch HTTP port (9200) so that other applications can communicate with the cluster.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: es-http
  type: ClusterIP
```

This YAML file creates a Service named `elasticsearch`, which targets pods with the label `app: elasticsearch`. It makes the Elasticsearch HTTP API accessible within the cluster through the cluster IP of the Service.

Конфигурация для лабы:

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