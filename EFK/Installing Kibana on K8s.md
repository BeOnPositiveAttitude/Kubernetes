### Understanding Kibana

Imagine Kibana as the lens (линза) that brings the details of your data into focus, allowing you to navigate through the complexities with ease. It connects to Elasticsearch, where your logs are stored, and lets you create visualizations such as charts and graphs. These visualizations are then organized into dashboards, providing you with insights at a glance.

### Deploying Kibana

Deploying Kibana involves creating a Deployment and a Service in Kubernetes. The Deployment ensures Kibana is running and manages replicas, while the Service makes Kibana accessible.

#### Creating the Kibana Deployment

1. **Configuration File**: Start by creating a configuration file for the Kibana Deployment. Let's name it `kibana-deployment.yaml`.

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: kibana
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: kibana
     template:
       metadata:
         labels:
           app: kibana
       spec:
         containers:
         - name: kibana
           image: docker.elastic.co/kibana/kibana:7.10.0
           env:
           - name: ELASTICSEARCH_HOSTS
             value: "http://elasticsearch:9200"
           ports:
           - containerPort: 5601
   ```

   This YAML file defines a Deployment named `kibana` with a single replica. It uses the official Kibana image and connects to Elasticsearch via the `ELASTICSEARCH_HOSTS` environment variable. Kibana uses port `5601` by default and communicates with ELasticsearch using an HTTP REST API. To secure Kibana, the security features of Elasticsearch should be enabled.

2. **Deploying Kibana**: With the configuration file ready, deploy Kibana using kubectl.

   ```shell
   $ kubectl apply -f kibana-deployment.yaml
   ```

### Exposing Kibana Through a Service

After deploying Kibana, you need to make it accessible. This is done by creating a Kubernetes Service.

1. **Service Configuration File**: Create a file named `kibana-service.yaml`.

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: kibana
   spec:
     type: NodePort
     ports:
     - port: 5601
       targetPort: 5601
       nodePort: 30001
     selector:
       app: kibana
   ```

   This Service exposes Kibana on a NodePort, making it accessible from outside the cluster.

2. **Creating the Service**: Apply the Service configuration using kubectl.

   ```shell
   $ kubectl apply -f kibana-service.yaml
   ```

### Accessing Kibana

With Kibana deployed and exposed, you can now access its interface using the IP address of any node in your cluster and the node port specified in the Service configuration (e.g., `http://<node-ip>:30001`).

To explore the raw logs shipped by Fluentd, you can access the **Discover** tab from the menu. You can use the *Kibana Query Language (KQL)* to search your data. However, you will first be required to specify an *index pattern* in order to select the data that has to be explored.

After having explored the logs, you can create dashboards to aggregate your data from various search operations. You can also import or export dashboards. Kibana dashboards are exported in the `.ndjson` format.