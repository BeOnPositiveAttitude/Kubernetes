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
