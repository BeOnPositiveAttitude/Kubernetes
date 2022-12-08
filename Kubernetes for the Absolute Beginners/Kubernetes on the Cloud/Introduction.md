K8s решения делятся на два типа - Self Hosted / Turnkey Solutions и Hosted Solutions (Managed Solutions)

### Self Hosted / Turnkey Solutions
- Вы разворачиваете ВМ
- Вы конфигурируете ВМ
- Вы используете скрипты для деплоя кластера
- Вы самостоятельно обслуживаете ВМ
- например: для деплоя Kubernetes в AWS используют kops или KubeOne

### Hosted Solutions (Managed Solutions)
- Kubernetes-As-A-Service
- Провайдер разворачивает ВМ
- Провайдер устанавливает Kubernetes
- Провайдер обслуживает ВМ
- например: Google Container Engine (GKE)

В Managed Solutions мы как правило не имеем доступа к master и worker нодам, соответственно не можем управлять версией K8s