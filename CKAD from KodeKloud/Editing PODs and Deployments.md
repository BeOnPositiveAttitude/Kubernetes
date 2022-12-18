Помните, вы не можете редактировать спецификацию существующего pod-а, кроме:
- spec.containers[*].image
- spec.initContainers[*].image
- spec.activeDeadlineSeconds
- spec.tolerations

Но если нужно редактировать другие опции, есть два способа:

Запустите команду `kubectl edit pod <pod-name>` и отредактируйте нужную опцию

Когда попытаетесь сохранить изменение, получите ошибку - Forbidden

Но при этом увидите сообщение, что измененная копия yaml файла сохранена в директории /tmp

Таким образом вы можете удалить бегущий pod командой `kubectl delete pod webapp`

И создать новый pod из файла в директории /tmp `kubectl create -f /tmp/kubectl-edit-ccvrq.yaml`

Второй способ - извлечь pod definition файл командой `kubectl get pod webapp -o yaml > my-new-pod.yaml`

Далее редактируем полученный файл, сохраняем, удаляем бегущий pod и создаем новый

В Deployment вы можете легко редактировать любое свойство pod template

Так как pod template является дочерним по отношению к спецификации Deployment, любое изменение свойства pod-а приведет к удалению и созданию нового pod-а

`kubectl edit deployment my-deployment`
