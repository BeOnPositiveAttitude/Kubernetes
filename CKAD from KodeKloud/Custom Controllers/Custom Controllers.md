В уроке про CRD мы научились создавать наш новый объект FlightTicket, информация о нем сохраняется в etcd. Теперь нам нужно мониторить статус объекта в etcd и выполнять некоторые действия, например делать вызовы к API https://book-flight.com/api для бронирования или отмены бронирования авиабилетов. Для этого нам нужен custom controller. Контроллер - это процесс, который непрерывно мониторит кластер и слушает events определенного объекта на предмет их изменения.