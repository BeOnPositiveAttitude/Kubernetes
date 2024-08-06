Во-первых мы изменим вес нашего приложения Reviews между его различными версиями. Затем создадим несколько правил маршрутизации, чтобы разные пользователи увидели разные версии нашего приложения.

Чтобы иметь возможность изменить вес трафика между разными версиями приложения, в первую очередь нужно задать эти версии. Это может быть сделано с помощью Destination Rules как мы обсуждали ранее. Для этого демо мы можем использовать дефолтные Destination Rules из каталога `samples/`. Применим манифесты командой: `kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml`.

Давайте создадим наш VirtualService под названием `reviews`. Он будет влиять на `review` source. В секции `http` мы создали два разных destinations. Первый для subset v1, второй для subset v2. Распределение веса здесь 75% на 25%. В сумме должно всегда быть 100%.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 75
    - destination:
        host: reviews
        subset: v2
      weight: 25
```

Проверяем с помощью команды `istio analyze`, что все в порядке.

Давайте создадим некоторое количество трафика для нашего приложения, чтобы увидеть как изменения в весе, повлияют на него.

`while sleep 0.01 ; do curl -sS 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage' &> /dev/null ; done`.

Переходим в WebUI Kiali в секцию Istio Config и видим Destination Rules, созданные из каталога `samples/`. Открываем DestinationRule `reviews` и видим три разных subsets, которым будут соответствовать Labels сервисов - v1, v2 и v3.

Проверим также VirtualService `reviews`. Видим распределение веса на полосе справа.

Теперь посмотрим Graph => Versioned app graph. Вес всех сервисов Reviews распределяется между v1 и v2. Когда мы открываем приложение в браузере, оно показывает только версию "без звездочек" и версию с черными звездочками. Версия с красными звездочками, она же v3, не отображается.

Теперь давайте остановим loop, которая генерирует входящий трафик и попытаемся достигнуть разницы 75%/25% в браузере. Как видно, v1 отображается чаще чем v2.

Давайте изменим распределение веса еще раз, но в этот раз через интерфейс Kiali. Идем в Istio Config => VS => Reviews.

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 60
        - destination:
            host: reviews
            subset: v2
          weight: 20
        - destination:
            host: reviews
            subset: v3
          weight: 20
```

Сначала у нас было только две версии Reviews, а теперь, для небольшого процента запросов, добавили другую версию сервиса. Проверяем в браузере и видим, что некоторые запросы возвращают версию с красными звездочками. Вернемся в терминал и создадим трафик с помощью цикла. Видим, что v3 также появилась на графе. Здесь представлены различные версии графов, некоторые сгруппированы как Services, некоторые как Workloads.

Давайте проверим Istio Config => VS => Reviews. Справа видим новое распределение веса. Если кликнуть "hosts", увидим обзор хостов. На этом детальном графе можно увидеть несколько больше информации о распределении веса. Видно, что трафика для v1 в три раза больше, чем для v2 и v3, как мы и настроили.

Теперь давайте попробуем пример, который использовали в лекции. Попробуем распределить трафик в соотношении 99% и 1%.

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 99
        - destination:
            host: reviews
            subset: v2
          weight: 1
```

Видим, что вес трафика идущего на v1 кардинально изменился. В браузере мы также практически не попадаем на версию v2 с черными звездочками.

Теперь выполним следующий пример. Мы хотим, чтобы некоторые из наших пользователей видели некоторые специфические версии приложения. Например наш Product Owner сказал нам, что каждый пользователь должен видеть версию без звездочек, но для специальной группы пользователей под названием "kodekloud" они хотят выпустить версию приложения со звездочками. Добавим новую секцию `match`. Когда пользователи из группы "kodekloud" войдут в приложение, они увидят версию с черными звездочками. А остальные пользователи будут видеть обычную версию без звездочек. Для этого мы добавим правило, которое будет выбирать запросы, имеющие в своем заголовке `end-user`. Оно будет проверять точное совпадение с `kodekloud`. Если запрос пройдет проверку на заданное правило, то он будет направлен на reviews v2. Остальные запросы будут направлены на reviews v1.

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - match:
        - headers:
            end-user:
              exact: kodekloud
      route:
        - destination:
            host: reviews
            subset: v2
    - route:
        - destination:
            host: reviews
            subset: v1
```

Как нам создать запрос, содержащий в заголовке поле `end-user` равное `kodekloud`? Для этого в приложении есть кнопка "Sign in". С ее помощью мы можем добавить `end-user` в заголовок запроса. Введем имя пользователя `kodekloud` и случайный пароль. После входа мы должны увидеть reviews v2 (версию с черными звездочками). Если мы выйдем, то снова увидим reviews v1 (версию без звездочек).

Теперь мы хотим добавить новую версию приложения reviews v3 для определенной группы людей (назовем их `testuser`), чтобы они ее протестировали и оставили обратную связь. Для этого добавим еще одну секцию `match`:

```yaml
...
spec:
  hosts:
    - reviews
  http:
    - match:
        - headers:
            end-user:
              exact: kodekloud
      route:
        - destination:
            host: reviews
            subset: v2
    - match:
        - headers:
            end-user:
              exact: testuser
      route:
        - destination:
            host: reviews
            subset: v3
    - route:
        - destination:
            host: reviews
            subset: v1
```

Введем имя пользователя `testuser` и случайный пароль. После входа мы должны увидеть reviews v3 (версию с красными звездочками).

Важен порядок следования route в манифесте VS. Если первым указать default route, то все запросы сразу будут идти на него, игнорируя созданные match-правила.

**Задание с Killercoda.**

Update the `notification` virtual service resource to add a route based on matching query parameter. If the request contains query parameter `testing=true` then route the request to `v2` , otherwise to `v1` .

*http default route:*

- host: `notification-service`
- subset: `v1`

*http query param match request route:*

- query param key: `testing`
- query key value: `true`
- query value match type: `exact`
- destination host: `notification-service`
- destination subset: `v2`

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
 name: notification
spec:
 hosts:
 - notification-service
 http:
 - match:
   - queryParams:
      testing:
       exact: "true"
   route:
   - destination:
      host: notification-service
      subset: v2

 - route:
   - destination:
       host: notification-service
       subset: v1
```

Пример запроса для проверки: `kubectl exec -it tester -- curl -s -X POST http://notification-service/notify?testing=true`.