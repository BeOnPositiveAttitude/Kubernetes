Ставим приложение bookinfo из каталога `samples/` командой: `k apply -f samples/bookinfo/platform/kube/bookinfo.yaml `.

Все ресурсы будут установлены в `default` namespace. Т.к. у нас установлен Istio мы ожидаем, что у каждого pod-а будет дополнительный proxy-контейнер, о котором мы говорили ранее. Однако на текущий момент каждый pod содержит всего лишь один контейнер. Почему? Мы можем использовать команду: `istioctl analyze` для поиска причины. И вот что мы видим в output:

`Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.`

Analyzer говорит нам, что не включена опция `istio-injection`. Что это значит? У вас может быть множество namespace-ов в K8s-кластере. `kube-system` - namespace, в котором запущены все ключевые компоненты, `default` - namespace по умолчанию, в котором разворачиваются приложения, если не задан конкретный namespace. Могут существовать другие приложения в других namespace-ах. Вы должны явно включить Istio sidecar injection на уровне namespace, чтобы Istio инжектировало proxy-сервисы в качестве sidecar-ов в развернутые в namespace приложения.

Для этого нужно повесить Label на нужный нам namespace командой:

`kubectl label namespace default istio-injection=enabled`.

Соответственно, чтобы явно отключить Istio sidecar injection нужно повесить Label с другим значением:

`kubectl label namespace default istio-injection=disabled`.

Теперь мы удаляем все что развернули командой: `k delete -f samples/bookinfo/platform/kube/bookinfo.yaml `. Вешаем Label, включающий Istio sidecar injection, на default namespace. После этого каждое новое приложение, развернутое в этом namespace, автоматически получит sidecar.

Развернем приложение заново: `k apply -f samples/bookinfo/platform/kube/bookinfo.yaml `.

Теперь команда: `istioctl analyze` говорит нам, что все в порядке: `No validation issues found when analyzing namespace: default`.