# Android MotionSender

Parent: [[modules/android-app]]

## Файл
`android/app/src/main/java/com/barkfluff/motionlink/motion/MotionSender.kt`

## Что делает
Открывает UDP `DatagramSocket` на эфемерном порту и шлёт сериализованный JSON [[api/motion-snapshot]] на `host:port` выбранного сервера.

## Архитектура отправки
- `Channel<MotionSnapshot>(Channel.CONFLATED)` — буфер на 1 элемент, новые snapshot'ы вытесняют старые. На случай, если отправка отстаёт от 30 Гц, теряем промежуточные кадры, но никогда не блокируем продьюсер.
- Coroutine на `Dispatchers.IO` читает канал в цикле и вызывает `socket.send(DatagramPacket)`.
- `send(snapshot)` — нонблокирующая `trySend`. Вызывается из callback'а [[modules/android-motion]].

## Состояние

```kotlin
enum class State { Idle, Ready, Failed }
val state: StateFlow<State>
```

- `Idle` — до `start()` / после `stop()`.
- `Ready` — сокет открыт, готов слать. UDP без рукопожатия → это не значит, что сервер реально слушает.
- `Failed` — `DatagramSocket()` упал на init.

В [[modules/android-ui]] / `MotionHUDScreen` это отображается цветной точкой в `ConnectionBadge` (зелёная / красная / серая).

## API
```kotlin
class MotionSender {
    enum class State { Idle, Ready, Failed }
    val state: StateFlow<State>
    fun start(server: DiscoveredServer)
    fun send(snapshot: MotionSnapshot)
    fun stop()
}
```

## Что НЕ делает
- Не обрабатывает потерянные пакеты — UDP best-effort, по протоколу клиент не ждёт ACK.
- Не делает reconnect при ошибке `send` — только логирует.
- Не пытается обнаружить, что сервер «отвалился» (нет keep-alive).

## Связанное
- [[modules/ios-sender]] — iOS-аналог через `NWConnection`
- [[api/motion-snapshot]]
- [[modules/protocol]] § Поток данных
