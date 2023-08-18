В этом демо мы добавим задержку в наш сервис Details.

Прежде чем создавать fault injection rule, нужно создать DestinationRule для того, чтобы у нас был subset, на котором это правило будет работать. Создадим VirtualService. Назовем его `details` и добавим `details` в секцию `host`. Данный VirtualService будет влиять на Service `details`. Добавим секцию `fault` под протоколом `http`. Этот fault добавит задержку в 7 секунд для 70% трафика в нашем Service Mesh.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details
spec:
  hosts:
    - details
  http:
  - fault:
      delay:
        percentage:
          value: 70.0
        fixedDelay: 7s
    route:
    - destination:
        host: details
        subset: v1
```

Применим данный манифест: `kubectl apply -f -<<EOF`.

Для тестирования fault injection мы вновь будем использовать `curl` в цикле. Переключимся в Kiali и посмотрим как задержка повлияет на весь Service Mesh. Сначала убедимся, что конфигурация корректна на вкладке "Istio Config". Далее переходим к Versioned app graph. Здесь мы должны увидеть наличие проблем с сервисом Details. Видим красную стрелку, идущую от "productpage" к "details", означающую проблемы с трафиком на этом участке. Также видим еще зеленую стрелку, идущую также от "productpage" к "details", означающую, что часть трафика до "details" все еще проходит нормально.

Если мы пойдем в браузер и обновим страницу, то увидим, что сервис Details часто не отвечает на запросы вовремя. Это из-за добавленного нами fault injection. Если мы продолжим обновлять страницу, то время от времени будем попадать в 30% "здорового" трафика и сервис Details отразит информацию.

Так с помощью добавленного fault injection мы можем понять каким образом ProductPage будет отвечать, если один из сервисов начнет тормозить, а также выявить его сильные и слабые стороны.