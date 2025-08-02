1. Обязательно проверяем, что у namespace есть метка `istio-injection=enabled`.

2. Прежде чем применять Virtual Service или Destination Rule нужно убедиться, что само приложение работает и отвечает через стандартный K8s service. 

3. Если задача заключается в траблшутинге проблем с прохождением трафика, то первым делом стоит посмотреть на сконфигурированные Virtual Services и/или Destination Rules.

4. Если мы настроили например Circuit Breaking, применили манифест и не видим результат, то причина может быть в том, что нужно некоторое время на распространение настроек по всем sidecars. А в случае с Circuit Breaker нам также нужно сгенерировать достаточное количество трафика, чтобы он сработал.

5. Правила маршрутизации не работают при прохождении трафика через Ingress Gateway:

   https://istio.io/latest/docs/ops/common-problems/network-issues/#route-rules-have-no-effect-on-ingress-gateway-requests

6. Envoy не поддерживает HTTP/1.0. При настройке например Nginx важно явно указывать версию HTTP не ниже 1.1:

   https://istio.io/latest/docs/ops/common-problems/network-issues/#envoy-wont-connect-to-my-http10-service

7. Важно корректно указывать HTTPS там, где это требуется:

   https://istio.io/latest/docs/ops/common-problems/network-issues/#sending-https-to-an-http-port

8. Ошибка при использование двух Gateways:

   https://istio.io/latest/docs/ops/common-problems/network-issues/#404-errors-occur-when-multiple-gateways-configured-with-same-tls-certificate

9. Fault Injection и Retries в одном Virtual Service:

   https://istio.io/latest/docs/ops/common-problems/network-issues/#virtual-service-with-fault-injection-and-retrytimeout-policies-not-working-as-expected

10. Опечатки, приводящие к неверной интерпретации задуманной логики (И/ИЛИ):

    https://istio.io/latest/docs/ops/common-problems/security-issues/#make-sure-there-are-no-typos-in-the-policy-yaml-file

11. Использование параметров, относящихся только к HTTP, в TCP-портах:

    https://istio.io/latest/docs/ops/common-problems/security-issues/#make-sure-you-are-not-using-http-only-fields-on-tcp-ports

12. Полезная команда, чтобы убедиться в применении политики авторизации на нужную нагрузку:

    https://istio.io/latest/docs/ops/common-problems/security-issues/#make-sure-the-policy-is-applied-to-the-correct-target

13. Тип политики авторизации `AUDIT` не запрещает выполнение запросов, а только логирует их:

    https://istio.io/latest/docs/ops/common-problems/security-issues/#pay-attention-to-the-action-specified-in-the-policy

14. Как убедиться, что политика авторизации действительно работает:

    https://istio.io/latest/docs/ops/common-problems/security-issues/#ensure-istiod-accepts-the-policies
 
Документация: https://istio.io/latest/docs/ops/common-problems/