В первую очередь Service Entry используется для определения сервисов, которые находятся вне Service Mesh (внешние по отношению к K8s-кластеру, например БД).

Workload Entry - это способ регистрации non-Kubernetes сервиса (например AWS EC2) в Istio Service Mesh. Таким образом зарегистрированный сервис ведет себя как обычный pod.

Мы как будто говорим - "Эй, Istio, это ВМ, и она не запущена внутри K8s, но я хочу, чтобы она была частью Mesh".

Соответственно мы можем сказать Istio защищать трафик, применять политики, мониторить и в целом обращаться с этим сервисом точно как с обычным pod-ом.

Workload Entry содержит конфигурацию EC2 как минимум с одним label и мы используем этот label для отправки трафика на соответствующий endpoint.

Пример Workload Entry:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: external-app-we
  namespace: backend
spec:
  address: 54.146.220.232
  labels:
    app: external
```

Здесь мы сообщаем Istio, что существует некий внешний сервис с указанным IP-адресом и мы присваиваем ему label `app: external`.

Далее мы создаем Service Entry:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-app-se
  namespace: backend
spec:
  hosts:
  - app.internal.com
  ports:
  - number: 80
    name: http
    protocol: TCP
  resolution: STATIC
  workloadSelector:   # здесь мы можем ссылаться как на pod-ы, так и на Workload Entries
    labels:
      app: external  
```

Таким образом мы регистрируем в Istio's Internal Service Registry новый endpoint `app.internal.com`, и трафик, приходящий на этот endpoint, будет маршрутизироваться на нагрузку, указанную в `workloadSelector` (т.е. на хост, указанный в Workload Entry).

<img src="image.png" width="800" height="400"><br>

Документация: https://istio.io/latest/docs/reference/config/networking/workload-entry/

Главно отличие между Workload Entry и Service Entry заключается в том, что Service Entry используется для маршрутизации трафика на внешний сервис (в случае когда исходящий из Mesh-а трафик жестко ограничен политикой), а Workload Entry используется для интеграции внешнего сервиса в Service Mesh.

Также в случае применения Workload Entry мы можем установить специальный агент на внешнюю ВМ и тогда сможем полноценно настроить mTLS, сбор логов и метрик с этой ВМ.

Workload Entry не может существовать сам по себе, работает только в связке с Service Entry.

### Demo

Ставим утилиту istioctl и делаем дамп профиля:

```shell
$ istioctl profile dump demo -o yaml > custom-profile.yaml
```

Внесем изменения в дамп профиля `custom-profile.yaml`:

```yaml
<...>
  meshConfig:
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
<...>
```

Валидируем:

```shell
$ istioctl validate -f custom-profile.yaml
```

Устанавливаем istio из созданного профиля:

```shell
$ istioctl install -f custom-profile.yaml -y
```

Чтобы сэмлуировать внешнее приложение, поставим непосредственно на ноду K8s-кластера Nginx:

```shell
$ sudo apt update -y && sudo apt install nginx -y
```

Проверяем работу Nginx:

```shell
$ curl http://localhost
```

Смотрим IP-адрес интерфейса `weave`:

```shell
$ ip -c addr show weave
```

Проверяем работу Nginx через этот интерфейс:

```shell
$ curl http://10.50.0.1
```

Включим Istio Injection для namespace `default`:

```shell
$ kubectl label ns default istio-injection=enabled
```

Создадим тестовый pod:

```shell
$ kubectl run test --image=nginx
```

Из тестового pod-а проверим доступность Nginx:

```shell
$ kubectl exec -it test -- curl -I http://10.50.0.1

root@test:/# curl -I -L http://www.wikipedia.org

HTTP/1.1 502 Bad Gateway
date: Sat, 19 Jul 2025 09:12:58 GMT
server: envoy
transfer-encoding: chunked
```