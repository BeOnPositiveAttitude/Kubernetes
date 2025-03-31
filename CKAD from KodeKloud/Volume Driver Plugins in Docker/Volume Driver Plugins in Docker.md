Volumes не управляются с помощью storage drivers, они управляются с помощью volume driver plugins.

Volume driver plugin по умолчанию - `local`, он помогает создавать volumes на Docker-хосте и сохраняет их данные в каталоге `/var/lib/docker/volumes`.

Существует множество других volume driver plugins, которые позволяют создавать volumes в решениях сторонних вендоров:
- Azure File Storage
- Convoy
- DigitalOcean Block Storage
- Flocker
- gce-docker
- GlusterFS
- NetApp
- RexRay
- Portworx
- VMware vSphere Storage

Некоторые из этих volume drivers поддерживают различные storage providers, например RexRay storage driver может быть использован для работы с:
- AWS EBS
- S3
- дисковые массивы EMC (Isilon, ScaleIO)
- Google Persistent Disk
- OpenStack Cinder

Мы можем указать определенный volume driver при запуске контейнера (например для Amazon EBS):

```shell
$ docker run -it --name mysql --volume-driver rexray/ebs --mount src=ebs-vol,target=/var/lib/mysql mysql
```

Это создаст контейнер и приаттачит volume из AWS Cloud.