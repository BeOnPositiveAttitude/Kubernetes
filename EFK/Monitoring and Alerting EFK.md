### Why Monitor the EFK Stack?

Monitoring the EFK stack helps ensure that your logging system is performing optimally. It allows you to detect issues early, such as Elasticsearch running out of storage or Fluentd experiencing high latency.

### Integrating Prometheus with EFK

Prometheus is an open-source monitoring solution for collecting and storing metrics. Integrating Prometheus with the EFK stack enables you to collect metrics about the performance and health of each component.

Prometheus allows `per job scrape interval` configuration that provides great flexibility in terms of which targets to scrape and how frequently.

#### Setting Up Prometheus

First, install Prometheus in your Kubernetes cluster. You can use the Prometheus Operator for easier management.

```shell
$ kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml
```

#### Configuring Prometheus to Monitor EFK Components

1. **Elasticsearch Metrics**: Use the `elasticsearch-exporter` to expose Elasticsearch metrics to Prometheus.

   https://github.com/prometheus-community/elasticsearch_exporter

   ```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: elasticsearch-exporter
     labels:
       team: backend
   spec:
     selector:
       matchLabels:
         app: elasticsearch-exporter
     endpoints:
     - port: http
   ```

2. **Fluentd Metrics**: Fluentd metrics can be exposed using the built-in Prometheus plugin.

   ```
   <source>
     @type prometheus
     port 24231
   </source>
   ```

3. **Kibana Metrics**: Kibana does not natively export Prometheus metrics, but you can use the `kibana-prometheus-exporter` plugin.

However, note that sensitive information and configuration data like secrets are not typically monitored using Prometheus.

### Visualizing Metrics with Grafana

Grafana is a powerful tool for visualizing metrics. Once Prometheus is collecting metrics from the EFK stack, you can use Grafana to create dashboards.

1. **Install Grafana**:

   ```shell
   $ kubectl create -f grafana.yaml
   ```

   where the yaml file would contain the required components for deployment:

   ```yaml
   ---
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: grafana-pvc
   spec:
     accessModes:
     - ReadWriteOnce
     resources:
       requests:
         storage: 1Gi
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     labels:
       app: grafana
     name: grafana
   spec:
     selector:
       matchLabels:
         app: grafana
     template:
       metadata:
         labels:
           app: grafana
       spec:
         securityContext:
           fsGroup: 472
           supplementalGroups:
           - 0
         containers:
         - name: grafana
           image: grafana/grafana:latest
           imagePullPolicy: IfNotPresent
           ports:
           - containerPort: 3000
             name: http-grafana
             protocol: TCP
           readinessProbe:
             failureThreshold: 3
             httpGet:
               path: /robots.txt
               port: 3000
               scheme: HTTP
             initialDelaySeconds: 10
             periodSeconds: 30
             successThreshold: 1
             timeoutSeconds: 2
           livenessProbe:
             failureThreshold: 3
             initialDelaySeconds: 30
             periodSeconds: 10
             successThreshold: 1
             tcpSocket:
               port: 3000
             timeoutSeconds: 1
           resources:
             requests:
               cpu: 250m
               memory: 750Mi
           volumeMounts:
           - mountPath: /var/lib/grafana
             name: grafana-pv
         volumes:
         - name: grafana-pv
           persistentVolumeClaim:
             claimName: grafana-pvc
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: grafana
   spec:
     ports:
     - port: 3000
       protocol: TCP
       targetPort: http-grafana
     selector:
       app: grafana
     sessionAffinity: None
     type: LoadBalancer
   ```

2. **Configure Grafana DataSource**:

   Add Prometheus as a DataSource in Grafana to start creating dashboards for your EFK metrics.

   Grafana supports multiple other datasources like Elasticserch, Graphite, InfluxDB, MySQL and even Google sheets.

A useful feature in Grafana is `templating` which allows creation of dynamic and reusable dashboards.

### Configuring Alerting

Alerting is crucial for being proactively notified about issues in your EFK stack before they escalate (обострятся).

#### Alerting with Prometheus Alertmanager

Prometheus Alertmanager can manage alerts sent by Prometheus. Define alert rules based on EFK metrics.

1. **Define Alert Rules**:

   For example, create an alert if Elasticsearch's heap usage is too high.

   ```yaml
   groups:
   - name: elasticsearch-alerts
     rules:
     - alert: ElasticsearchHighHeapUsage
       expr: elasticsearch_jvm_memory_used_bytes / elasticsearch_jvm_memory_max_bytes > 0.9
       for: 5m
       labels:
         severity: critical
       annotations:
         summary: "High Heap Usage (instance {{ $labels.instance }})"
         description: "Elasticsearch node {{ $labels.node }} heap usage is above 90%."
   ```

2. **Configure Alertmanager**:

   Set up Alertmanager to send notifications through email, Slack, or other channels when alerts are triggered.

   ```yaml
   global:
     resolve_timeout: 5m
   route:
     receiver: 'slack-notifications'
   receivers:
   - name: 'slack-notifications'
     slack_configs:
     - channel: '#alerts'
   ```

### Lab

Команда `nohup` предотвращает распространение системного сигнала SIGHUP (Signal Hang UP), задача которого - сообщать запущенным процессам о потере соединения с управляющим терминалом пользователя.

Установка `elasticsearch-exporter`:

```shell
$ wget https://github.com/prometheus-community/elasticsearch_exporter/releases/download/v1.7.0/elasticsearch_exporter-1.7.0.linux-amd64.tar.gz
$ tar xzvf elasticsearch_exporter-1.7.0.linux-amd64.tar.gz
$ nohup elasticsearch_exporter-1.7.0.linux-amd64/elasticsearch_exporter --es.uri="http://localhost:30200" &
$ curl http://localhost:9114/metrics
```

Установка Prometheus:

```shell
$ wget https://github.com/prometheus/prometheus/releases/download/v2.51.1/prometheus-2.51.1.linux-amd64.tar.gz
$ tar xzvf prometheus-2.51.1.linux-amd64.tar.gz
```

Добавим в конфиг `prometheus.yml` новый target:

```yaml
- job_name: "elasticsearch"
  static_configs:
  - targets: ["localhost:9114"]
```

Запустим Prometheus:

```shell
$ nohup ./prometheus --config.file=prometheus.yml &
```

Установка Grafana:

```shell
$ wget https://dl.grafana.com/enterprise/release/grafana-enterprise-10.4.1.linux-amd64.tar.gz
$ tar xzvf grafana-enterprise-10.4.1.linux-amd64.tar.gz
$ nohup ./bin/grafana-server &
```

Open the menu on the left of the Grafana Welcome page under **Home**. Under the **Connections** submenu, click on **Data sources** => **Add data source** and select **Prometheus**.

Under **Connection**, enter `http://localhost:9090/` for Prometheus server URL. Scroll to the bottom of this page and click on **Save and Test**.

Having set up our basic observability stack for the elasticsearch metrics, let's learn how to query our metrics in the Grafana dashboard.

Select **Explore** from the Grafana menu. You will be presented with a workspace to create and run your queries. Prometheus as a data source has already been selected for you as a result of your previous task.

There are two ways through which you can create a query here - either by using the **builder** or by using the **code**.

Let's select **builder** for now and view the value of a simple metric. From the Metric dropdown, select `elasticsearch_cluster_health_active_primary_shards` and `cluster` and `docker-cluster` as the key-value pair under **Label filters**. After clicking on **Run query**, you can view the value of the current number of primary shards in the cluster that are active and assigned to nodes.

You can also select other metrics, and create a dashboard for visualizing the vitals of your Elasticsearch components.

This dashboard can be used as a reference:

https://grafana.com/grafana/dashboards/14191-elasticsearch-overview/

Reference for elasticsearch metrics:

https://github.com/prometheus-community/elasticsearch_exporter?tab=readme-ov-file#configuration

Define an alert rule in Prometheus for high Elasticsearch heap usage.

1. Navigate to the `prometheus-2.51.1.linux-amd64` folder and create a file named `rules.yml` with the following content:

   ```yaml
   groups:
   - name: elasticsearch
     rules:
     - alert: HighElasticsearchHeapUsage
       expr: elasticsearch_jvm_memory_used_bytes{job="elasticsearch"} / elasticsearch_jvm_memory_max_bytes{job="elasticsearch"} > 0.05
       for: 2m
       labels:
         severity: critical
       annotations:
         summary: "High Elasticsearch heap usage (instance {{ $labels.instance }})"
         description: "Elasticsearch instance {{ $labels.instance }} has high heap usage ({{ $value }} bytes used) for more than 2 minutes."
   ```

2. Edit the `prometheus.yml` file and add the newly created rules file to it under the `rule_files` section:

   ```yaml
   rule_files:
     - "rules.yml"
   ```

3. Restart Prometheus.

4. In the Prometheus UI, navigate to the **Alerts** section. You will find your defined alert `HighElasticsearchHeapUsage`. This will remain in **pending** state for up to two minutes, and then go into the **firing** state.

Установка AlertManager:

```shell
$ wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
$ tar xzvf alertmanager-0.27.0.linux-amd64.tar.gz
$ nohup ./alertmanager --config.file=alertmanager.yml &
```

Добавим в конфиг Prometheus адрес AlertManager:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]
```

Перезапустим Prometheus. В веб-морде AlertManager спустя две минуты должен появится алерт.

Переходим в каталог `/root/scripts` и запускаем python-скрипт:

```bash
$ python3 alert_receiver.py
```

В терминале увидим алерты.