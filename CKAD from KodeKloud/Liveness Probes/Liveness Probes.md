Предположим мы запустили веб-сервер в Docker: `docker run nginx`.

Если приложение "упало", то контейнер остановится и прекратит обслуживать пользователей, т.к. Docker не является оркестратором контейнеров.

В случае K8s контейнер будет перезапускаться при падениях и мы увидим возрастающее число restarts.

Но что если в нашем приложении баг, оно зависло и фактически не работает, но сам контейнер при этом жив?

Нам нужно только перезапустить контейнер и на помощь приходят Liveness Probe.

Liveness Probes могут быть настроены на периодическую проверку доступности нашего приложения. Если проверка провалена, тогда контейнер убивается и создается заново.

Существуют различные вариант проверки "здоровья" нашего приложения, например HTTP-тест до API приложения, TCP-тест до определенного порта, запуск скрипта внутри контейнера, который проверяет health status приложения.

Пример проверки доступности API-ручки:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: simple-webapp
  name: simple-webapp
spec:
  containers:
  - image: simple-webapp
    name: simple-webapp
    ports:
      - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /api/healthy
        port: 8080
      initialDelaySeconds: 10   # если мы точно знаем, что приложение поднимается минимум 10 секунд, то можем задать интервал задержки перед проверкой
      periodSeconds: 5          # как часто выполнять проверку
      failureThreshold: 8       # по умолчанию после 3 неудачных попыток проба останавливается, можем переопределить на большее число попыток
```

Пример проверки доступности TCP-порта:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: simple-webapp
  name: simple-webapp
spec:
  containers:
  - image: simple-webapp
    name: simple-webapp
    ports:
      - containerPort: 8080
    livenessProbe:
      tcpSocket:
        port: 3306
```

Пример проверки успешности выполнения команды/скрипта:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: simple-webapp
  name: simple-webapp
spec:
  containers:
  - image: simple-webapp
    name: simple-webapp
    ports:
      - containerPort: 8080
    livenessProbe:
      exec:
        command:
        - cat
        - /app/is_healthy
```