При тестировании приложения в `development` namespace оно прекрасно работало, при переносе в `production` namespace появилась ошибка `CrashLoopBackOff`.

<img src="image.png" width="800" height="100"><br>

Ошибка означает, что список переменных окружения в контейнере слишком большой.

<img src="image-1.png" width="800" height="500"><br>