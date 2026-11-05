```bash
$ kubectl autoscale deployment nginx-deployment --max=3 --cpu=80%
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  maxReplicas: 3
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 80
        type: Utilization
    type: Resource
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
```

```bash
$ timeout 10s sh -c 'while true; do curl -s http://flask-prometheus-app-service > /dev/null; done'
```

```yaml
prometheus:
  url: http://prometheus-server.prometheus.svc.cluster.local
  port: 80

rules:
  custom:
    - seriesQuery: 'http_requests_total{namespace!="", pod!=""}'
      resources:
        overrides:
          namespace: {resource: "namespace"}
          pod: {resource: "pod"}
      name:
        matches: "^(.*)_total"
        as: "${1}_per_second"
      metricsQuery: 'sum(rate(<<.Series>>[5m])) by (<<.GroupBy>>)'
```