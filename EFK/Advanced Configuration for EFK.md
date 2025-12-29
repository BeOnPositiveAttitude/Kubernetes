### Custom Fluentd Plugins for Log Enrichment

Log enrichment (обогащение) involves adding additional context to your logs, making them more informative and easier to analyze. Custom Fluentd plugins can be developed or configured to enrich logs with extra metadata, such as Kubernetes labels, environment information, or application-specific data.

#### Creating a Custom Fluentd Filter Plugin

1. **Set up your Fluentd environment**: Ensure you have Fluentd installed and running in your Kubernetes cluster. You can use the Fluentd daemonset for easy deployment.

2. **Develop the plugin**: Fluentd plugins are typically written in Ruby. Here's a simple example of a custom filter plugin that adds a static field to all logs:

   ```ruby
   require 'fluent/plugin/filter'
   
   module Fluent::Plugin
     class MyCustomFilter < Filter
       Fluent::Plugin.register_filter('my_custom_filter', self)
   
       def configure(conf)
         super
         # You can add configuration parameters here
       end
   
       def filter(tag, time, record)
         # Add a custom field to the record
         record["additional_info"] = "static_value"
         record
       end
     end
   end
   ```

3. **Install the plugin**: After developing your plugin, you need to make it available to Fluentd. If you package it as a gem, you can install it using Fluentd's `fluent-gem` command.

4. **Configure Fluentd to use the plugin**: Modify your Fluentd configuration to use the new filter. Here's an example configuration snippet:

   ```
   <filter **>
     @type my_custom_filter
   </filter>
   ```

The plugin that you see above is the `filter` plugin. It is used to modify the structure of a log message. We are using it here in conjunction with our custom plugin that adds a new field to the logs.

Another important plugin that Fluentd uses is the `buffer` plugin which temporarily stores logs before forwarding them to the destination. It, thereby, helps in avoiding data loss.

#### Testing and Debugging

Ensure to test your plugin thoroughly (тщательно) in a development environment before deploying it to production. Fluentd provides detailed logs that can help you debug issues with your custom plugins.

### Elasticsearch Index Management for Performance

Proper index management is crucial (ключевой) for maintaining the performance of your Elasticsearch cluster. This involves strategies such as index rollover, sharding, and replicas configuration.

#### Index Rollover

Index rollover helps in managing indices (индексы) based on certain criteria like size, age, or document count. It allows you to automate the creation of new indices when the current ones meet specified conditions.

1. **Create an index template**:

   ```json
   PUT _template/my_logs_template
   {
     "index_patterns": ["logs-*"],
     "settings": {
       "number_of_shards": 3,
       "number_of_replicas": 1
     }
   }
   ```

2. **Set up an ILM (Index Lifecycle Management) policy**:

   ILM policies define the conditions under which indices should be transitioned between different phases (such as hot, warm, cold, and delete) based on factors like age, size, and other criteria.

   ILM policies allow the automation of the index management process, which can help optimize resource usage and improve performance. For example, you can use ILM policies to automatically move indices from hot storage (fast, expensive storage) to warm storage (slower, cheaper storage) as they age, or to delete indices that are no longer needed based on a specified timeframe.

   Overall, ILM policies help you manage your Elasticsearch indices more efficiently by automating common lifecycle management tasks.

   ```json
   PUT _ilm/policy/my_logs_policy
   {
     "policy": {
       "phases": {
         "hot": {
           "actions": {
             "rollover": {
               "max_size": "5GB",
               "max_age": "30d"
             }
           }
         },
         "delete": {
           "min_age": "90d",
           "actions": {
             "delete": {}
           }
         }
       }
     }
   }
   ```

3. **Apply the ILM policy to your index template**:

   ```json
   PUT _template/my_logs_template
   {
     "settings": {
       "index.lifecycle.name": "my_logs_policy"
     }
   }
   ```

#### Sharding and Replicas Configuration

Properly configuring shards and replicas can significantly impact your Elasticsearch cluster's performance and resilience.

- **Shards**: Distribute data across multiple nodes in the cluster to improve performance. The minimum value of master-eligible (подходящих в качестве) ELasticsearch nodes in a cluster is 3 to ensure high availability. The optimal number of shards depends on the size of your data and the capacity of your nodes.

- **Replicas**: Provide high availability and redundancy. In case of a node failure, replicas ensure that your data is not lost.

```json
PUT /my_logs-000001
{
  "settings": {
    "index": {
      "number_of_shards": 3,
      "number_of_replicas": 2
    }
  }
}
```

Apart from the above configurations, changing the refresh interval for an Elasticsearch index is another vital (жизненно важная) setting for improving write performance in an environment with intense log load.

### Lab

The Elasticsearch index setting critical for improving write performance in a log-heavy environment is **Changing the refresh interval**.

The refresh interval controls how often the changes made to the index are made visible to search operations. In a log-heavy environment, setting a higher refresh interval can significantly improve write performance by reducing the frequency of index refreshes, which can be resource-intensive.

Custom FluentD filter, file name must be `filter_my_custom_filter.rb`:

```ruby
require 'fluent/plugin/filter'

class Fluent::Plugin::MyCustomFilter < Fluent::Plugin::Filter
  Fluent::Plugin.register_filter('my_custom_filter', self)

  config_param :additional_data, :string, default: 'static_info'

  def filter(tag, time, record)
    record['additional_data'] = @additional_data
    record
  end
end
```

`fluent.conf` file content:

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
<filter **>
  @type my_custom_filter
  additional_data static_info
</filter>
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

FluentD DaemonSet:

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
        - name: pluginpath
          mountPath: /fluentd/plugins
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
      - name: pluginpath
        hostPath:
          path: /root/fluentd/plugins
```

Применить ILM-политику из json-файла:

```shell
$ curl -X PUT "http://localhost:30200/_ilm/policy/my_logs_policy" -H 'Content-Type: application/json' -d @my_logs_policy.json
```

Проверить, что политика создана:

```shell
$ curl -X GET "http://localhost:30200/_ilm/policy"
```

Index Template JSON:

```json
{
  "index_patterns": ["fluentd-*"],
  "settings": {
    "index.lifecycle.name": "my_logs_policy",
    "index.lifecycle.rollover_alias": "my-logs"
  }
}
```

Применить шаблон из json-файла:

```shell
$ curl -X PUT "http://localhost:30200/_template/my_logs_template" -H 'Content-Type: application/json' -d @my_logs_template.json
```

Проверить, что шаблон создан:

```shell
$ curl -X GET "http://localhost:30200/_template"
```