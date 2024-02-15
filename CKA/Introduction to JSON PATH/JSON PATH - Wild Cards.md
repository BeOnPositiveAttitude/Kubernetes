Получить цены/цвета всех объектов в словаре:

<img src="image-9.png" width="900" height="500"><br>

Получить модели всех объектов в списке (нужно заключать JSON PATH запрос в кавычки):

<img src="image-10.png" width="900" height="500"><br>

Использование wildcard в комбинации словари/списки:

<img src="image-11.png" width="900" height="500"><br>

Задача из лабы, получить значения указанные ниже из файла `q9.json`.

```json
[
  "Kailash",
  "Malala"
]
```

Итоговый запрос: `cat q9.json | jpath '$.prizes[?(@.year == 2014)].laureates[*].firstname'`.