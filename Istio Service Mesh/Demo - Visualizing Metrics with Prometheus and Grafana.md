В этом демо мы посмотрим на Prometheus Dashboard и исследуем некоторые метрики. Приложение "Book Info App" развернуто в нашем кластере с настройками по умолчанию.

Создадим поток трафика с помощью цикла. Чтобы открыть Prometheus Dashboard используем команду: `istioctl dashboard prometheus`. Здесь мы можем выполнять запросы Prometheus. Prometheus не предназначен для графического отображения данных по метрикам. Для этого может быть использована Grafana.

Давайте создадим несколько метрик. Если мы введем `istio` в поле `Expression`, то увидим множество вариантов на выбор. Некоторые идут из Istio Control Plane, некоторые из приложений. Выберем для примера `istio_agent_go_info` и нажмем "Execute". Эта метрика предоставляет информацию об окружении Go. Также есть кнопка "Graph", которая покажет соответствующий нашей метрике граф.

Теперь попробуем метрику `istio_requests_total`, которая показывает общее количество приходящих запросов. На графе мы можем играться с временным интервалом.

Введем следующий запрос: `istio_requests_total{destination_service="productpage.default.svc.cluster.local"}`. Здесь мы можем увидеть метрики запросов, приходящих от нашего Gateway.

Далее отфильтруем запросы к сервису Reviews: `istio_requests_total{destination_service="reviews.default.svc.cluster.local",destination_version="v3"}`.

Теперь посмотрим на Grafana Dashboard: `istioctl dashboard grafana`. В разделе "Dashboards" видим каталог "istio". Там находятся дефолтные dashboard-ы, которые были развернуты вместе с Grafana. Откроем для примера "Istio Control Plane Dashboard".