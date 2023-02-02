Предположим у нас есть файл values.yaml:
```yaml
regions:
  - ohio
  - newyork
  - ontario
  - london
  - singapore
  - mumbai
```

И мы хотим получить ConfigMap следующего вида:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: RELEASE-NAME-regioninfo
data:
  regions:
    - "ohio"
    - "newyork"
    - "ontario"
    - "london"
    - "singapore"
    - "mumbai"
```

Для этого нужно использовать range:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-regioninfo
data:
  regions:
  {{- range .Values.regions }}
    - {{ . | quote }}           #т.к. это list, то в начале нам нужен символ "-" , точка означает обращение к объекту внутри списка, и далее заключаем в кавычки
  {{- end }}
```

Range устанавливает scope при каждой итерации по циклу.