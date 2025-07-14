Можно вывести содержимое любого профиля istio, доступного для установки:

```shell
$ istioctl profile list
$ istioctl profile dump default -o yaml > default.yaml
```

Istio Operator дает большую гибкость в настройке устанавливаемых компонентов. Например можно включить/отключить какие-либо компоненты, изменить resources и т.д.

Установить istio из кастомного профиля:

```shell
$ istioctl install -f default.yaml
```

Документация: https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/

Также можно кастомизировать установку с помощью helm. Для этого нужно вывести используемые values:

```shell
$ helm show values istio/base > istio_base.yaml
$ helm show values istio/istiod > istiod.yaml
$ helm show values istio/gateway > istio_gateway.yaml
```

Отредактировать values-файлы в соответствии с нашими требованиями и установить:

```shell
$ helm install istio-base istio/base -n istio-system -f istio_base.yaml
$ helm install istiod istio/istiod -n istio-system -f istiod.yaml
$ helm install istio-ingress istio/gateway -n istio-ingress -f istio_gateway.yaml
```

Можно внести изменения в уже существуюущую инсталляцию istio. Для этого делаем дамп профиля:

```shell
$ istioctl profile dump default -o yaml > default.yaml
```

Вносим необходимые изменения и применяем:

```shell
$ istioctl upgrade -f default.yaml
```

Аналогично с помощью helm:

```shell
$ helm show values istio/istiod > istiod.yaml
$ helm upgrade istiod istio/istiod -n istio-system -f istiod.yaml
```

Удалить istio с помощью утилиты istioctl:

```shell
$ istioctl uninstall --set profile=default purge
```

Удалить istio с помощью helm:

```shell
$ helm uninstall istio-ingress -n istio-ingress
$ helm uninstall istiod -n istio-system
$ helm uninstall istio-base -n istio-system
```