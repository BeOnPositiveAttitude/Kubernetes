Давайте создадим gateway для нашего приложения. Gateway сконфигурирует наш Service Mesh для приема трафика извне кластера.

`kubectl apply -f istio-1.18.0/samples/bookinfo/networking/bookinfo-gateway.yaml`.

Смотрим по какому IP доступен наш кластер minikube: `minikube ip`.

Задаем для удобства переменную: `export INGRESS_HOST=$(minikube ip)`.

И еще одну переменную для номер порта: `export INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')`.

Проверяем, что ссылка работает: `curl http://$INGRESS_HOST:$INGRESS_PORT/productpage`.

Удалось заставить работать только на версии Istio 1.10.3 (как в уроке) и minikube 1.24.0!!! На свежих версиях ошибка сертификата.