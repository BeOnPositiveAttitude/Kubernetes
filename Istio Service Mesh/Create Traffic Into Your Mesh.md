Давайте создадим gateway для нашего приложения. Gateway сконфигурирует наш Service Mesh для приема трафика извне кластера.

`kubectl apply -f istio-1.18.0/samples/bookinfo/networking/bookinfo-gateway.yaml`.

Смотрим по какому IP доступен наш кластер minikube: `minikube ip`.

Задаем для удобства переменную: `export INGRESS_HOST=$(minikube ip)`.

И еще одну переменную для номер порта: `export INGRESS_PORT=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')`.

Проверяем, что ссылка работает: `curl http://$INGRESS_HOST:$INGRESS_PORT/productpage`.

Удалось заставить работать только на версии Istio 1.10.3 (как в уроке) и minikube 1.24.0!!! На свежих версиях ошибка сертификата.

Создадим поток трафика с помощью простого скрипта:

`while sleep 0.01 ; do curl -sS 'http://'"$INGRESS_HOST"':'"$INGRESS_PORT"'/productpage' &> /dev/null ; done`.

Теперь на Kiali Dashboard мы должны увидеть Graph нагрузки.

Теперь искусственно создадим проблему, удалим Deployment: `kubectl delete deployments/productpage-v1`.

На Kiali Dashboard видим красноту, т.к. теперь трафик не поступает на страницу продукта и далее на остальные модули.