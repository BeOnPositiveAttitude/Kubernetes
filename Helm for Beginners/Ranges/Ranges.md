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

Пример из лабы - список key/value:

```yaml
{{- with .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $.Values.serviceAccount.name }}
  labels:
    {{- range $key, $val := $.Values.serviceAccount.labels }}
    {{ $key }}: {{ $val }}
    {{- end }}
    app: webapp-color
{{- end }}
```

Итоговый результат:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp-sa
  labels:
    mode: proxy
    tier: frontend
    type: web
    app: webapp-color
```

Если бы мы написали первое, что приходит в голову:

```yaml
{{- with .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $.Values.serviceAccount.name }}
  labels:
  {{- range $.Values.serviceAccount.labels }}
    {{ . }}
  {{- end }}
    app: webapp-color
{{- end }}
```

То получили только значения без ключей:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp-sa
  labels:
    proxy
    frontend
    web
```