Включаем ingress в minikube: `minikube addons enable ingress`.

Этот вариант работает с Docker в Linux, но может не работать с Docker на macOS.

В этом случае нужно удалить minikube-кластер и запустить заново с опцией:

```bash
minikube delete
minikube start --vm=true
```

Скачиваем утилиту `istioctl` командой: `curl -L https://istio.io/downloadIstio | sh -`.

Добавляем новую директорию в PATH: `export PATH=$PWD/bin:$PATH`.

Либо копируем исполняемый файл из каталога `./bin/istioctl` в каталог `/usr/local/bin/`.