Создать Deployment: `kubectl create deployment nginx --image=nginx:1.16`

Смотреть статус развертывания: `kubectl rollout status deployment nginx`

Смотреть историю:
```
controlplane $ kubectl rollout history deployment nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
```
При этом видно, что поле Change-Cause пустое

Смотреть статус определенной Revision:
```
controlplane $ kubectl rollout history deployment nginx --revision=1
deployment.apps/nginx with revision #1
Pod Template:
Labels:       app=nginx
pod-template-hash=78449c65d4
Containers:
nginx:
Image:      nginx:1.16
Port:       <none>
Host Port:  <none>
Environment: <none>
Mounts:      <none>
Volumes:
```

Записать команду, использованную для обновления Deployment в поле Change-Cause (по сути данное поле представляет из себя запись в блоке `annotations`):
```
controlplane $ kubectl set image deployment nginx nginx=nginx:1.17 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/nginx image updated
```
```
controlplane $ kubectl rollout history deployment nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment nginx nginx=nginx:1.17 --record=true
```

Допустим мы обновили Deployment, изменив образ nginx на latest:
```
controlplane $ kubectl edit deployments.apps nginx --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/nginx edited
```
```
controlplane $ kubectl rollout history deployment nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment nginx nginx=nginx:1.17 --record=true
3         kubectl edit deployments.apps nginx --record=true
```
```
controlplane $ kubectl rollout history deployment nginx --revision=3
deployment.apps/nginx with revision #3
Pod Template:
  Labels:       app=nginx
        pod-template-hash=787f54657b
  Annotations:  kubernetes.io/change-cause: kubectl edit deployments.apps nginx --record=true
  Containers:
   nginx:
    Image:      nginx
    Port:       <none>
    Host Port:  <none>
    Environment:  <none>
    Mounts:     <none>
  Volumes:
```

Откатиться на определенный Revision:
```
controlplane $ kubectl rollout undo deployment nginx --to-revision=1
deployment.apps/nginx rolled back
```
```
controlplane $ kubectl describe deployments. nginx | grep -i image:
Image: nginx:1.16
```

Предположим, что при редактировании Deployment мы по ошибке указали несуществующий образ, например `nginx:does-not-exist`. Т.к. по умолчанию используется стратегия обновления `RollingUpdate`, K8s удалит одну реплику (при условии, что у нас их несколько, например 6), попытается создать несколько новых и в итоге застопорится. Оставшиеся 5 реплик при этом останутся работать на старой версии, обеспечивая тем самым непрерывный доступ к нашему приложению. Таким образом последующие реплики не будут пересоздаваться, т.к. возникла проблема уже с первой.