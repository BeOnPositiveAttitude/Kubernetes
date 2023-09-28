Давайте посмотрим как настроить Istio с собственным корневым сертификатом, когда мы устанавливаем Istio-кластер.

Сначала нужно создать каталог для наших сертификатов `ca-certs` внутри корневого каталога Istio и перейти в него.

Сгенерируем наш root-сертификат командой: `make -f ../tools/certs/Makefile.selfsigned.mk root-ca`. Делается в linux, т.к. нужна утилита `make`.

Создаются четыре файла:
- `root-ca.conf` - конфигурация для openssl для генерации корневого сертификата
- `root-cert.csr` - сгенерированный CSR для корневого сертификата
- `root-cert.pem` - сгенерированный корневой сертификат
- `root-key.pem` - сгенерированный корневой ключ

Теперь создадим наши промежуточные сертификаты командой: `make -f ../tools/certs/Makefile.selfsigned.mk localcluster-cacerts`.

Корневые сертификаты не должны использоваться напрямую, т.к. это очень опасно и не очень практично.

Также нужно удалить предустановленный Istio или хотя бы удалить namespace `istio-system`, чтобы была возможность сконфигурировать Istio для использования наших сертификатов. Очистим также namespace `default` скриптом: `istio-1.13.0/samples/bookinfo/platform/kube/cleanup.sh`.

Создадим namespace `istio-system` заново `kubectl create ns istio-system`.

Далее перейдем в каталог `localcluster-cacerts` и создадим секрет, содержащий созданные нами промежуточные сертификаты:

`kubectl create secret generic cacerts -n istio-system --from-file=ca-cert.pem --from-file=ca-key.pem --from-file=cert-chain.pem --from-file=root-cert.pem`

Теперь установим Istio обратно, чтобы центр сертификации Istio (Certificate Authority) прочитал сертификаты и ключ из файла секрета:

`istioctl install --set profile=demo`

Также установим обратно Kiali, Grafana и Prometheus: `kubectl apply -f samples/addons`.

Вернем обратно установку нашего приложения "Book Info App" и дефолтные правила для трафика:

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

Применим политику аутентификации, разрешающую только mTLS-трафик для наших нагрузок.

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "default"
spec:
  mtls:
    mode: STRICT
```

Теперь проверим, подписаны ли наши нагрузки именно тем сертификатом, который мы только что внедрили. Попробуем получить цепочку сертификатов сервиса Details c помощью OpenSSL в момент, когда подключаемся к сервису Product Page.

`kubectl exec -it "$(kubectl get pod -l app=details -o jsonpath={.items..metadata.name})" -c istio-proxy -- openssl s_client -showcerts -connect productpage:9080 > httpbin-proxy-cert.txt`

Т.к. CA-сертификат используемый в данном примере является самоподписанным, то ожидаемо увидим ошибку `verify error:num=19:self signed certificate in certificate chain`.

В файле `httpbin-proxy-cert.txt` содержатся сертификаты и мы очистим оставшуюся часть избыточной информации с помощью команды:

`sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' httpbin-proxy-cert.txt | sed 's/^\s*//' > certs.pem`

По итогу в файле `certs.pem` мы видим сертификаты, извлеченные из трафика между двумя сервисами.

Теперь разделим их на четыре разных файла командой: `split -p "-----BEGIN CERTIFICATE-----" certs.pem proxy-cert-`. Опция `-p` не найдена. Делим вручную.

Проверим, что корневой сертификат совпадает.

Сначала "сдампим" корневой сертификат, созданный в начале уроке:

`openssl x509 -in ca-certs/localcluster/root-cert.pem -text -noout > /tmp/root-cert.crt.txt`

Затем "сдампим" третий по счету сертификат, который мы извлекли из трафика между сервисами:

`openssl x509 -in proxy-cert-3.pem -text -noout > /tmp/pod-root-cert.crt.txt`

Проверим совпадают ли они: `diff -s /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt`.

Мы убедились, что Istio использует наш корневой сертификат в трафике Mesh-а.

Второй шаг состоит в том, чтобы убедиться, что CA-сертификат также совпадает.

Получаем сообщение `Files root-cert.crt.txt and pod-root-cert.crt.txt are identical`.

Сначала "сдампим" CA-сертификат, созданный в начале уроке:

`openssl x509 -in ca-certs/localcluster/ca-cert.pem -text -noout > /tmp/ca-cert.crt.txt`

Затем "сдампим" второй по счету сертификат, который мы извлекли из трафика между сервисами:

`openssl x509 -in proxy-cert-2.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt`

Проверим совпадают ли они: `diff -s /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt`.

Получаем сообщение `Files ca-cert.crt.txt and pod-cert-chain-ca.crt.txt are identical`.

Проверим также цепочку сертификатов от корневого сертификата к сертификату нагрузки.

`openssl verify -CAfile <(cat ca-certs/localcluster/ca-cert.pem ca-certs/localcluster/root-cert.pem) ./proxy-cert-1.pem`.

Получаем сообщение: `./proxy-cert-1.pem: OK`.