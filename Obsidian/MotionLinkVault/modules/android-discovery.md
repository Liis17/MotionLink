# Android Discovery

Parent: [[modules/android-app]]

## Файл
`android/app/src/main/java/com/barkfluff/motionlink/discovery/DiscoveryService.kt`

## Что делает
Реализует клиентскую часть discovery-протокола (см. [[modules/protocol]]). Один сокет, два корутинных job'а:
- **broadcastLoop** — раз в секунду шлёт `"MOTIONLINK_DISCOVER\n"` на `255.255.255.255:58930`.
- **receiveLoop** — блокирующий `socket.receive()` на том же сокете, парсит JSON-ответы.

## Сокет
`DatagramSocket(null)` + ручной `bind(InetSocketAddress(0))` чтобы выставить `reuseAddress` и `broadcast` **до** bind. Эфемерный порт (`0`) — ОС выбирает.

## MulticastLock
Android Wi-Fi-стек по умолчанию глушит чужие multicast/broadcast пакеты для экономии батареи. Для приёма ответов нужен `WifiManager.MulticastLock` с `setReferenceCounted(false)` и `acquire()` на время работы discovery.

Освобождается в `stop()` и в любом сценарии завершения. `release()` обёрнут в `runCatching { if (isHeld) ... }` — двойной release бросает.

## Парсинг ответа
`parseResponse(text)` через `org.json.JSONObject`. `optString("name", "")` (Android org.json НЕ умеет вернуть null из optString — пустая строка трактуется как «нет имени»). Если JSON битый — возвращаем `(null, 58930)`, всё равно показываем сервер по IP.

## Защита от рефлексии
Если ответ начинается с `MOTIONLINK_DISCOVER` — это наша собственная broadcast-проба, отражённая роутером или собственным стеком. Игнорируется.

## Дедупликация
`addOrIgnore` — `_servers.update { list -> if (list.any { it.id == server.id }) list else list + server }`. `id == host` (см. [[api/discovered-server]]).

## API
```kotlin
class DiscoveryService(context: Context) {
    val servers: StateFlow<List<DiscoveredServer>>
    fun start()
    fun stop()
}
```

## Жизненный цикл
- `start()` идемпотентен (повторный вызов — no-op, если сокет уже жив).
- `stop()` отменяет job'ы, закрывает сокет, освобождает MulticastLock, очищает список.
- Вызывается из `MotionLinkApp.DisposableEffect`: start при `Searching`, stop при переходе в `Streaming`.

## Связанное
- [[modules/protocol]] — wire-формат discovery
- [[modules/ios-discovery]] — iOS-аналог (POSIX-сокет вместо DatagramSocket)
- [[api/discovered-server]]
