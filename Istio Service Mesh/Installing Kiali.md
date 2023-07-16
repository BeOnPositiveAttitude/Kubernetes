Установим все, что есть в каталоге addons: `kubectl apply -f istio-1.18.0/samples/addons/`.

Важно заметить, что все эти addon-ы не настроены с точки зрения производительности и безопасности. Они предназначены только для демонстрационных целей.

Проверяем статус Deployment-а Kiali: `kubectl -n istio-system rollout status deployment/kiali `.

Проверяем статус Service Kiali: `kubectl -n istio-system get svc kiali`.

Запускаем Dashboard Kiali: `istioctl dashboard kiali`.

Доступ по ссылке: `http://localhost:20001/kiali`.