# iOS Sender — отправка пакетов

Parent: [[index]]

## Назначение
Открывает UDP-соединение на `host:port`, кодирует `MotionSnapshot` в компактный JSON и шлёт каждый снапшот одной датаграммой. Без подтверждений и keep-alive.

## Файлы
- `ios/MotionLink/MotionSender.swift` — один класс `MotionSender`.

## Тип
`@Observable final class MotionSender`

Publish-state:
- `isConnected: Bool` — мостится из `NWConnection.stateUpdateHandler`
- `lastSentAt: Date?` — обновляется в `send` completion

`@ObservationIgnored`:
- `connection: NWConnection?`
- `queue: DispatchQueue("motionlink.sender")`
- `encoder: JSONEncoder` (без форматирования)

## Ключевые методы
| Метод | Описание |
|-------|----------|
| `start(host:port:)` | stop() предыдущего, создаёт `NWConnection(host:port: .udp)`, навешивает `stateUpdateHandler`, `start(queue:)` |
| `send(_ snapshot:)` | `JSONEncoder.encode(snapshot)` → `connection.send(content:completion:)` |
| `stop()` | `connection.cancel()`, `isConnected = false` |

## Зависимости
- Использует: `Network` (`NWConnection`, `NWEndpoint`), `Observation`, `Foundation`
- Принимает: `MotionSnapshot` (см. [[api/motion-snapshot]])
- Используется в: [[modules/ios-app]] — `ContentView.connect(to:)` навешивает `motion.onUpdate = sender.send`

## Важные детали
- **NWConnection поверх UDP без рукопожатия** — состояние `.ready` означает только, что локальный стек готов. Не гарантия, что сервер реально слушает.
- `isConnected` обновляется на `main`, чтобы `MotionHUDView` мог реактивно переключать зелёную точку.
- Все ошибки `send` молча игнорируются (только `lastSentAt` не обновится). Это соответствует требованию протокола: «не падать, продолжать слать» ([[modules/protocol]]).
- `JSONEncoder` без `outputFormatting` → ключи в порядке `MotionSnapshot.CodingKeys` (по умолчанию — в порядке свойств), без пробелов/переносов.

## Связанное
- [[modules/protocol]] — поведение и формат на проводе
- [[modules/ios-discovery]] — откуда берутся host/port
