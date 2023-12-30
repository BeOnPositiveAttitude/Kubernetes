[Ссылка](https://kubernetes.io/docs/concepts/cluster-administration/addons/) на документацию K8s по установке сетевых плагинов.

При установке weave нужно проверить, что опция `IPALLOC_RANGE` в манифесте DaemonSet weave совпадает со значением опции `--cluster-cidr` в конфигурации kube-proxy. Для этого смотрим описание pod-а kube-proxy: `kubectl -n kube-system describe po kube-proxy-nlv79`.

```yaml
    Command:
      /usr/local/bin/kube-proxy
      --config=/var/lib/kube-proxy/config.conf
      --hostname-override=$(NODE_NAME)
...
    Mounts:
      /var/lib/kube-proxy from kube-proxy (rw)
...
Volumes:
  kube-proxy:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      kube-proxy
    Optional:  false
```

Смотрим откуда монтируется конфиг kube-proxy `config.conf` - из ConfigMap `kube-proxy`.

Смотрим описание ConfigMap: `kubectl -n kube-system describe cm kube-proxy` и ищем значение опции `clusterCIDR: 10.244.0.0/16`.

Скачиваем манифест weave: `wget https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml`.

И прописываем для контейнера `weave` необходимую переменную `IPALLOC_RANGE` (по умолчанию ее там нет):

```yaml
      containers:
        - name: weave
          env:
            - name: IPALLOC_RANGE
              value: 10.244.0.0/16
```

Применяем манифест через команду apply, наслаждаемся.