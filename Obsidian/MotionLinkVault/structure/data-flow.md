# Поток данных

Parent: [[structure/overview]]

## Жизненный цикл сессии

```
[запуск приложения]
        │
        ▼
   AppState = .searching
        │
        ├── DiscoveryService.start()
        │       └── открывает UDP-сокет, раз в 1 с шлёт "MOTIONLINK_DISCOVER\n"
        │           на 255.255.255.255:58930
        │
        ▼
  сервер отвечает JSON → DiscoveredServer добавлен в список
        │
        ▼
  пользователь жмёт «Подключиться» → connect(to:)
        │
        ├── discovery.stop()
        ├── sender.start(host:port:)        ← NWConnection UDP
        ├── motion.onUpdate = sender.send   ← связь сенсор → отправка
        └── motion.start()                  ← Timer 30 Hz + CoreMotion
        │
        ▼
   AppState = .streaming(server)
        │
        ▼  каждые ~33 мс
  CMMotionManager.deviceMotion → MotionSnapshot → JSONEncoder → NWConnection.send → UDP-пакет
        │
        ▼
  пользователь жмёт «Отключиться» → disconnect()
        │
        ├── motion.stop()
        ├── sender.stop()                   ← NWConnection.cancel()
        └── discovery.start()               ← снова в .searching
```

## Где формируется пакет

1. `MotionManager.tick()` собирает `MotionSnapshot` ([[api/motion-snapshot]]) каждый тик `Timer` 30 Гц.
2. Вызывает `onUpdate(snapshot)`.
3. В `ContentView.connect(to:)` колбэк замыкан на `sender.send(snapshot)`.
4. `MotionSender.send` кодирует `MotionSnapshot` через `JSONEncoder` (без форматирования) и шлёт через `NWConnection.send(content:completion:)`.

## Где происходит discovery

`DiscoveryService` использует **сырой POSIX-сокет**, не `NWConnection`, потому что `Network.framework` не умеет нормально слать `255.255.255.255` broadcast. Но `NWBrowser` всё равно стартует — только чтобы вызвать системный диалог разрешения Local Network. См. [[modules/ios-discovery]].

## Android — поток идентичен

Тот же state-machine `AppState`, тот же протокол. Отличия в реализации:

| Шаг | iOS | Android |
|-----|-----|---------|
| Discovery socket | raw POSIX `socket()` + `SO_BROADCAST` | `DatagramSocket` + `broadcast=true` + `WifiManager.MulticastLock` |
| Permission prompt | `NWBrowser` ради Local Network alert | manifest `CHANGE_WIFI_MULTICAST_STATE` + `INTERNET` |
| Тикер | `Timer.scheduledTimer(0.033)` на MainActor | `delay(33L)` в coroutine на `Dispatchers.Default` |
| Sender socket | `NWConnection(.udp)` | `DatagramSocket` + `DatagramPacket` |
| Источник углов | `CMDeviceMotion.attitude` (CoreMotion) | `SensorManager.getOrientation(rotationMatrix, _)` из `TYPE_ROTATION_VECTOR` |
| Источник accel | `userAcceleration` (g) | `TYPE_LINEAR_ACCELERATION` (м/с²) / 9.80665 |

См. [[modules/android-app]] и поддочки.

## Связанное
- [[modules/protocol]] — что лежит внутри пакета
- [[modules/ios-motion]] — источник сенсоров iOS
- [[modules/ios-sender]] — выходной сокет iOS
- [[modules/android-motion]] — источник сенсоров Android
- [[modules/android-sender]] — выходной сокет Android
