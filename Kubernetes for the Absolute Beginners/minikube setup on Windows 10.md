Установка minikube на Windows 10 и VMware Workstation Player 16.

Скачиваем утилиты kubectl и minikube, например в каталог `C:\Tools`, прописываем этот каталог в Path для переменной среды пользователя, также туда прописываем каталог `C:\Program Files (x86)\VMware Player`, т.к. там лежит файл vmrun.exe. И еще на всякий случай создаем каталог `C:\Program Files (x86)\VMware Workstation`, копируем туда файл vmrun.exe и также прописываем в Path.

В `C:\Users\Aidar\.minikube\logs` можно увидеть логи запуска minikube.

При попытке запустить minikube возникает ошибка создания ВМ, т.к. не может сделать диск SCSI, нужно зайти в Workstation и создать его руками, старый удалить, перевесить на шину 0:0. После этого должно завестись.