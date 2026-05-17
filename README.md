# MotionLink

Клиент для трансляции данных датчиков движения телефона по UDP на локальный сервер. Реализован для **iOS** (SwiftUI + CoreMotion) и **Android** (Jetpack Compose + SensorManager).

## Что собирает

С частотой **~30 Гц** телефон читает свои датчики и собирает один срез данных:

| Поле | Единица | Источник |
|---|---|---|
| `t` | секунды (Unix epoch) | системное время |
| `roll`, `pitch`, `yaw` | градусы | iOS: `CMDeviceMotion.attitude` / Android: `SensorManager.getOrientation` поверх `TYPE_ROTATION_VECTOR` |
| `acceleration {x,y,z}` | g (без гравитации) | iOS: `userAcceleration` / Android: `TYPE_LINEAR_ACCELERATION` ÷ 9.80665 |
| `gravity {x,y,z}` | g | iOS: `gravity` / Android: `TYPE_GRAVITY` ÷ 9.80665 |
| `rotationRate {x,y,z}` | рад/с | iOS: `rotationRate` / Android: `TYPE_GYROSCOPE` |

## В каком виде отправляет

Транспорт — **только UDP**, без рукопожатий и подтверждений. Один JSON-объект на датаграмму, компактный, UTF-8, ~200–300 байт:

```json
{
  "t": 1779993600.123,
  "roll": -12.4, "pitch": 34.1, "yaw": 87.2,
  "acceleration": {"x": 0.012, "y": -0.143, "z": 0.981},
  "gravity":      {"x": 0.000, "y": 0.000, "z": -1.000},
  "rotationRate": {"x": 0.002, "y": -0.001, "z": 0.004}
}
```

## Как находит сервер

UDP-discovery в локальной сети:

1. Клиент раз в секунду шлёт broadcast `MOTIONLINK_DISCOVER\n` на `255.255.255.255:58930` с эфемерного порта.
2. Сервер, слушающий на `0.0.0.0:58930`, отвечает однострочным JSON на адрес отправителя: `{"name": "имя", "port": 58930}` (оба поля опциональны).
3. IP сервера клиент берёт из `sockaddr` ответа, **не** из JSON.
4. Найденные серверы дедуплицируются по IP и показываются в списке. После выбора пользователем discovery останавливается и открывается UDP-поток данных на `host:port` из ответа.

Полная спецификация протокола: [`PROTOCOL.md`](PROTOCOL.md).

## Структура репозитория

```
ios/        — iOS-клиент (Swift / SwiftUI / CoreMotion / Network)
android/    — Android-клиент (Kotlin / Compose / SensorManager / DatagramSocket)
Obsidian/   — vault с документацией архитектуры (см. Obsidian/MotionLinkVault/index.md)
```

## Минимальный сервер для проверки

```python
import socket, json
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("0.0.0.0", 58930))
while True:
    data, addr = sock.recvfrom(2048)
    if data.startswith(b"MOTIONLINK_DISCOVER"):
        sock.sendto(b'{"name":"dev","port":58930}', addr)
    else:
        print(json.loads(data))
```
