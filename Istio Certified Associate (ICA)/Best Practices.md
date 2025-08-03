1. Задавать маршруты по умолчанию для сервисов:

   https://istio.io/latest/docs/ops/best-practices/traffic-management/#set-default-routes-for-services

2. Разбивать большие конфигурации VS и DR на несколько маленьких:

   https://istio.io/latest/docs/ops/best-practices/traffic-management/#split-virtual-services

3. Сначала обновляем конфигурацию DR, а уже после конфигурацию VS во избежание 503-ошибки:

   https://istio.io/latest/docs/ops/best-practices/traffic-management/#avoid-503-errors-while-reconfiguring-service-routes

4. Использование mTLS там, где это возможно:

   https://istio.io/latest/docs/ops/best-practices/security/#mutual-tls

5. Использование DENY-политики по умолчанию. Запрещаем все, за исключением того, что явно разрешено:

   https://istio.io/latest/docs/ops/best-practices/security/#use-default-deny-patterns

6. Не используем в конфигурации Gateway для хостов значение `*`:

   https://istio.io/latest/docs/ops/best-practices/security/#avoid-overly-broad-hosts-configurations

7. Изоляция чувствительных сервисов:

   https://istio.io/latest/docs/ops/best-practices/security/#isolate-sensitive-services

Документация: https://istio.io/latest/docs/ops/best-practices/