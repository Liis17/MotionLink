# iOS Discovery — поиск сервера

Parent: [[index]]

## Назначение
Раз в секунду шлёт UDP-broadcast `MOTIONLINK_DISCOVER\n` на `255.255.255.255:58930`, собирает ответы и публикует список `DiscoveredServer` в UI.

## Файлы
- `ios/MotionLink/DiscoveryService.swift` — весь модуль (один класс + struct).

## Тип
`@Observable final class DiscoveryService`
- `static let discoveryPort: UInt16 = 58930`
- `private static let probe = "MOTIONLINK_DISCOVER\n"`
- Publish-state: `servers: [DiscoveredServer]`, `isSearching: Bool`
- Внутреннее: POSIX-`sock: Int32`, два `DispatchSource` (timer + read), `NWBrowser` (см. ниже).

## Ключевые методы
| Метод | Описание |
|-------|----------|
| `start()` | Запрашивает Local Network permission, открывает сокет, запускает read-source + 1 Гц timer-source |
| `stop()` | Cancel'ит таймер и read-source, закрывает сокет, гасит `NWBrowser` |
| `triggerLocalNetworkPermission()` | Стартует фейковый `NWBrowser` на `_motionlink._udp.` — иначе iOS 14+ молча режет broadcast |
| `openSocket()` | `socket(AF_INET, SOCK_DGRAM)` + `SO_BROADCAST=1` + `SO_REUSEADDR=1` + `bind(0.0.0.0:0)` |
| `sendProbe()` | `sendto(...)` пробы на `255.255.255.255:58930` |
| `receive()` | `recvfrom`, фильтрация эхо-броадкаста, парс JSON, добавление сервера в список |
| `parseReply(_:)` | Берёт `name: String?`, `port: UInt16?` из JSON. Оба опциональны |
| `addServer(_:)` | На главном потоке append'ит, если ещё нет в списке |

## Зависимости
- Использует: `Foundation`, `Darwin` (raw socket), `Network` (только для разрешения permission), `Observation`
- Используется в: [[modules/ios-app]] (ContentView)
- Производит: `DiscoveredServer` → [[api/discovered-server]]

## Важные детали
- **Почему raw POSIX, а не NWConnection / NWListener:** `Network.framework` не поддерживает рассылку на `255.255.255.255`. `NWBrowser` тут существует **только** чтобы поднять системный prompt Local Network — без него все наши broadcast-пакеты iOS просто выкинет.
- **Фильтр своего эха:** некоторые сети рефлектируют broadcast обратно. Если пришёл пакет, начинающийся с `MOTIONLINK_DISCOVER`, — игнорируем.
- **Дедупликация:** по `host` (это `id` структуры). Один IP = одна карточка.
- **Таймаута нет:** discovery работает бесконечно до выбора пользователя или `stop()`.
- **Все sock-операции** на `DispatchQueue "motionlink.discovery"`. Публикация в `servers` — на `main` через `DispatchQueue.main.async`.
- Endianness: `dest.sin_port = 58930.bigEndian` — обязательно, network byte order.

## Связанное
- [[modules/protocol]] — wire-формат
- [[api/discovered-server]] — тип результата
