Данная лекция является логический продолжением урока "Pod Networking".

Сетевое решение, настроенное нами вручную, имеет таблицу маршрутизации, отражающую маппинг какие маршруты прописаны на каких хостах. Когда пакет отправляется от одного pod-а к другому, он выходит в сеть, к маршрутизатору, и находит путь к ноде, на которой находится целевой pod. Это работает для небольших окружений и простых сетей. Но в больших окружениях с сотнями нод в кластере и сотнями pod-ов на каждой ноде это непрактично. Таблица маршрутизации может не поддерживать такое большое количество записей.

Давайте посмотрим на K8s-кластер как на компанию, а на ноды как на ее филиалы (office sites). В каждом филиале у нас есть различные отделы (departments - finance, payroll, marketing), а в каждом отделе есть различные бюро (в этой аналогии pod-ы). Кто-то из бюро-1 хочет отправить пакет в бюро-3 и передает его курьеру (office boy). Все, что он знает, это то, что пакет нужно доставить в бюро-3, и ему все равно, кто и как его перевезет. Курьер берет пакет, садится в свою машину, смотрит целевой адрес в GPS и, используя указатели на улицах, находит путь в филиал назначения. Доставляет пакет в отдел расчета заработной платы, который в свою очередь перенаправляет пакет в бюро-3. В данной ситуации это хорошо работает.

<img src="image.png" width="700" height="500"><br>


Далее мы расширяемся в другие регионы и страны, и этот процесс больше не работает.



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