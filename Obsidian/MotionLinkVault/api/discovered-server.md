# DiscoveredServer

Parent: [[index]]

## Где определено
`ios/MotionLink/DiscoveryService.swift`

```swift
struct DiscoveredServer: Identifiable, Hashable, Sendable {
    let host: String       // IP из sockaddr ответа (НЕ из JSON)
    let port: UInt16       // из JSON `port`, либо 58930 по умолчанию
    let name: String?      // из JSON `name`, либо nil → UI покажет "Сервер"

    var id: String { host }
}
```

## Семантика идентификации
- `id == host` — **один IP = один сервер**. Это сознательное упрощение: дедупликация по IP, разные порты на одном хосте сольются в одну карточку.
- `Hashable` — позволяет использовать в `ForEach` напрямую.

## Источники значений

| Поле | Откуда |
|------|--------|
| `host` | `inet_ntop` от `sockaddr_in` из `recvfrom` |
| `port` | `(json["port"] as? Int).flatMap { UInt16(exactly: $0) }` ?? `58930` |
| `name` | `json["name"] as? String` |

JSON-ответ сервера: см. [[modules/protocol]] § Discovery.

## Использование в UI
- [[modules/ios-ui]] / `DiscoveryView` → `ServerCard` показывает `name ?? "Сервер"` и `"\(host):\(port)"`.
- [[modules/ios-ui]] / `MotionHUDView` → `connectionBadge` отображает только `host:port` (без name).

## Связанное
- [[modules/ios-discovery]] — где создаётся
- [[api/app-state]] — носит этот тип в `.streaming(DiscoveredServer)`
