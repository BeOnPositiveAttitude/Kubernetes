Сначала смотрим статус нод: `kubectl get nodes`.

Если кластер создан с помощью инструмента kubeadm и компоненты control plane развернуты в виде pod-ов, проверяем их статус: `kubectl -n kube-system get pods`.

Если компоненты control plane развернуты в виде сервисов, тогда нужно проверить статус соответствующих сервисов.

На master-нодах:

```bash
service kube-apiserver status
service kube-controller-manager status
service kube-scheduler status
```

На worker-нодах:

```bash
service kubelet status
service kube-proxy status
```

Далее смотрим логи компонентов control plane.

Если кластер создан с помощью инструмента kubeadm: `kubectl -n kube-system logs kube-apiserver-master`.

Если компоненты control plane развернуты в виде сервисов, то на master-нодах смотрим: `sudo journalctl -u kube-apiserver`.

[Ссылка](https://kubernetes.io/docs/tasks/debug/debug-cluster/) на документацию по troubleshooting-у кластеров.