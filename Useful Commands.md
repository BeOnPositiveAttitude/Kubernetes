Вынести в переменную имя первого контейнера в pod-е и сразу вывести полученное значение на экран:

```bash
HTTP=$(kubectl get pod  -o jsonpath='{.spec.containers[0].name}') ; echo "HTTP: $HTTP"
HTTP: httpd-php-container
```

Вынести в переменную имя второго контейнера в pod-е и сразу вывести полученное значение на экран:

```bash
MYSQL=$(kubectl get pod -o jsonpath='{.spec.containers[1].name}')  ; echo "MYSQL: $MYSQL"
MYSQL: mysql-container
```

Вынести в переменную имя pod-а и сразу вывести полученное значение на экран:

```bash
POD=$(kubectl get pods -o jsonpath='{.metadata.name}') ; echo "POD: $POD"
POD: lamp-wp-56c7c454fc-s7xf5
```

Далее можно удобно использовать полученные переменные, например: `kubectl logs -f $POD -c $HTTP`.

Посмотреть переменные окружения в контейнере: `kubectl exec -it $POD -c $HTTP -- env | grep -i mysql`.

При наличии нескольких контекстов можно посмотреть объекты из другого контекста: `kubectl get nodes --context cluster2`.