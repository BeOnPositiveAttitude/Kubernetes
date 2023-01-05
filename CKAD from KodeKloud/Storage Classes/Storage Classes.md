В качестве примера приведены три definition файла - PV, PVC и Pod

Мы создаем PVC из Google Cloud Persistent Disk, проблема в том, что прежде чем создать PV, мы должны сначала вручную создать диск в Google CLoud командой:

`gcloud beta compute disks create --size 1GB --region us-east1 pd-disk`, где pd-disk - имя диска в Google Cloud, которое мы указали в PV

Каждый раз когда приложению требуется storage, мы должны вручную создать диск в Google Cloud, вручную создать PV definition файл

Это называется static provisioning of volumes

Было бы удобно, если бы volumes выделялись автоматически, когда это нужно приложению

Для этого существуют Storage Classes, где мы можем определить provisioner, например Google storage, который может автоматически выделять storage в Google Cloud и аттачить его к pod-ам, когда появился соответствующий claim

Это называется dynamic provisioning of volumes

Для этого нужно создать объект Storage Class, пример в файле sc-definition.yaml

Вернемся к первому примеру, теперь когда у нас есть Storage Class, нам больше не нужен PV definition файл, т.к. PV и связанный с ним storage будет создаваться автоматически, после того как создан Storage Class

Теперь при создании PVC, указанный в нем Storage Class использует соответствующий provisioner (kubernetes.io/gce-pd в нашем примере) для выделения нового диска нужного объема в GCP, создаст PV и свяжет его с PVC

Важно помнить, что PV все равно создается, просто мы делаем это не в ручную, это происходит автоматически с помощью Storage Class

Далее приведены примеры Storage Class definition файлов для GCE - Silver, Gold, Platinum, поэтому они так называются - Storage Class