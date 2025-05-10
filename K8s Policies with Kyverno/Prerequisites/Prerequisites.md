Для чего может понадобится Kyverno?

Изначально сам K8s не выполняет каких-либо validation checks над манифестами, кроме проверки корректности синтаксиса.

Мы же к примеру хотим, чтобы у каждого манифеста проставлялся label с названием команды (team), которая написала этот манифест. Кроме того мы хотим запретить использование тэга `latest`.

Плюс еще ряд ограничений:

<img src="image.png" width="400" height="250"><br>

Kyverno - это policy enforcement engine, который позволяет нам создавать различные правила/политики, которые обеспечивают соблюдение требуемых ограничений на конфигурацию объектов в кластере.

Если объект не удовлетворяет заданным политикам, то его создание будет отклонено.

Для начала вспомним какой путь проходит запрос после ввода команды `kubectl apply -f`.

<img src="image-1.png" width="1000" height="300"><br>

Больше всего в этой цепочке нас интересует Admission Controller, который способен выполнять как валидацию, так и модификацию запросов. Функциональность Admission Controller расширяется различными плагинами.

Если у нас есть некое специфическое требование, под которое пока не существует нужного плагина, то мы можем задействовать функционал ValidatingAdmissionWebhook и MutatingAdmissionWebhook, которые в свою очередь могут вызывать какое-либо third-party решение с определенной логикой.

Как изменится схема прохождения запроса:

<img src="image-2.png" width="1000" height="300"><br>

Теперь когда Admission Controller получает запрос, то на этапах Mutating Admission (изменение исходного запроса) и Validating Admission (проверка запроса) он будет обращаться к Kyverno с помощью настроенного webkook.

Установка Kyverno: https://kyverno.io/docs/installation/methods/

```shell
$ helm repo add kyverno https://kyverno.github.io/kyverno/
$ helm repo update
$ helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

Создадим простой Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
    # team: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: container1
        image: nginx
```

И политику Kyverno, которая требует наличия label с названием команды, создавшей манифест:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-deployment-team-label
spec:
  validationFailureAction: Enforce
  rules:
  - name: require-deployment-team-label
    match:
      any:
      - resources:
          kinds:
          - Deployment
    validate:
      message: "you must have label `team` for all deployments"
      pattern:
        metadata:
          labels:
            team: "?*"   # как минимум один символ в значении label "team"
```

Секция `validationFailureAction` может принимать следующие значения:
- `Audit` - в случае несоответствия заданным правилам создание ресурса разрешается, но будет создан специальный отчет
- `Enforce` - в случае несоответствия заданным правилам создание ресурса запрещается

The `validationFailureAction` attribute controls admission control behaviors for resources that are not compliant with a policy. If the value is set to `Enforce`, resource creation or updates are blocked when the resource does not comply. When the value is set to `Audit`, a policy violation is logged in a `PolicyReport` or `ClusterPolicyReport` but the resource creation or update is allowed.

Если мы попытаемся создать наш тестовый Deployment без label `team`, то получим ошибку:

```shell
Error from server: error when creating "STDIN": admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/default/nginx-deployment was blocked due to the following policies 

require-deployment-team-label:
  require-deployment-team-label: 'validation error: you must have label `team` for
    all deployments. rule require-deployment-team-label failed at path /metadata/labels/team/'
```