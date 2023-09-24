В этом уроке мы увидим разницу между `no peer authentication policy` и включенным mTLS.

Для этого демо мы создадим новый namespace. Когда мы включим mTLS *namespace-wide* в namespace `default` не-mTLS трафик приходящий от этого нового namespace будет предотвращен.

Начнем с очистки namespace `default` скриптом: `istio-1.13.0/samples/bookinfo/platform/kube/cleanup.sh`.

Затем заново развернем приложения "Book Info App": `kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml`.

Создадим новый namespace: `kubectl create ns bar`. Далее создадим просто приложение под названием HTTPbin.

HTTPbin поможет нам выполнять curl-запросы к другим сервисам: `kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n bar`.

Если у вашего namespace не включена опция `istio-injection=enabled`, то с помощью команды `istioctl kube-inject` вы также можете вручную инжектировать istio-proxy sidecar-ы. Ручное инжектирование изменит конфигурацию Deployment путем добавления в него конфигурации proxy. Это работает немного по другому.