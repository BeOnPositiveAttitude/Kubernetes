StatefulSet - Name: redis-cluster

Replicas: 6

Pods status: Running (All 6 replicas)

Image: redis:5.0.1-alpine, Label = app: redis-cluster

container name: redis, command: ["/conf/update-node.sh", "redis-server", "/conf/redis.conf"]

Env: name: 'POD_IP', valueFrom: 'fieldRef', fieldPath: 'status.podIP' (apiVersion: v1)

Ports - name: 'client', containerPort: '6379'

Ports - name: 'gossip', containerPort: '16379'

Volume Mount - name: 'conf', mountPath: '/conf', readOnly:'false' (ConfigMap Mount)

Volume Mount - name: 'data', mountPath: '/data', readOnly:'false' (volumeClaim)

volumes - name: 'conf', Type: 'ConfigMap', ConfigMap Name: 'redis-cluster-configmap',

Volumes - name: 'conf', ConfigMap Name: 'redis-cluster-configmap', defaultMode = '0755'

volumeClaimTemplates - name: 'data'

volumeClaimTemplates - accessModes: 'ReadWriteOnce'

volumeClaimTemplates - Storage Request: '1Gi'