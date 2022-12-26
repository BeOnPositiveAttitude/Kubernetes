Как мониторить потребление ресурсов в K8s или что еще более важно, что именно мониторить?

Допустим мы хотим знать количество нод в кластере, сколько из них "healthy", утилизацию CPU, RAM, дисков и сети

Также мы хотим значть количество pod-ов и их метрики - потребление CPU и RAM

Изначально K8s не поставляется со встроенным решением для мониторинга

Существуют сторонние проекта для мониторинга K8s - Metrics Server, Prometheus, Elastic Stack, DATADOG, Dynatrace

В данном курсе рассматривается только Metrics Server

Heapster - один из первоначальных проектов для мониторинга K8s, но сейчас он уже Deprecated и одна из его версий сформировалась в Metrics Server

На один кластер K8s нужен один Metrics Server

Metrics Server - это in-memory решение, то есть данные не хранятся на диске, соответственно нельзя посмотреть исторические данные

K8s запускает на каждой ноде кластера агент kubelet, который получает инструкции от API мастера и запускает pod-ы на нодах

Kubelet также содержит субкомпонент cAdvisor (Container Advisor), который отвечает за сбор performance-метрик с pod-ов и их публикацию через kubelet API, чтобы они были доступны для metrics server

Для включения metrics server в minikube: `minikube addons enable metrics-server`

Для остальных `git clone https://github.com/kubernetes-incubator/metrics-serve` и `kubectl create -f deploy/1.8+/`

Далее понадобится некоторое время для сбора метрик кластера и далее можно дать команду:

`kubectl top node` или `kubectl top pod`