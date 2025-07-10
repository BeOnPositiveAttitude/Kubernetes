Страница релизов на GitHub: https://github.com/istio/istio/releases?page=9

Скачать утилиту `istioctl` можно командой:

```shell
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.18.2 sh -
```

Далее добавляем новую директорию в PATH:

```shell
$ export PATH=$PWD/bin:$PATH
```

Либо копируем исполняемый файл из каталога `./bin/istioctl` в каталог `/usr/local/bin/`.

Смотреть доступные для установки профили:

```shell
$ istioctl profile list
```

<img src="image.png" width="800" height="400"><br>

Установка Istio:

```shell
$ istioctl install --set profile=demo -y
```

Валидация установки:

```shell
$ kubectl -n istio-system get pods
```

Второй вариант (занимает около 20-30 минут):

```shell
$ istioctl verify-install
```

Третий вариант:

```shell
$ istioctl analyze -n <namespace>
$ istioctl analyze -A
```

Включить Istio для определенного namespace:

```shell
$ kubectl label namespace default istio-injection=enabled
```

Валидация:

```shell
$ kubectl get ns default --show-labels
```

После включения Istio нужно удалить и развернуть заново имеющуюся нагрузку в namespace.

Также можно инжектировать Istio для определенного deployment, а не для всего namespace.

```shell
$ istioctl kube-inject -f bookinfo.yaml | kubectl apply -f -
```

Установка с помощью helm:

<img src="image-1.png" width="1000" height="400"><br>

Выполнить валидацию yaml-файла, содержащего istio-компонент:

```shell
$ istioctl validate file.yaml
```