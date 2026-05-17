# iOS UI

Parent: [[index]]

## Назначение
Два экрана: поиск сервера и HUD-стрим значений сенсоров. Оба написаны на SwiftUI и завязаны на наблюдаемые объекты `DiscoveryService` / `MotionManager` / `MotionSender`.

## Файлы
- `ios/MotionLink/DiscoveryView.swift` — экран поиска (список карточек серверов).
- `ios/MotionLink/MotionHUDView.swift` — экран стрима (значения сенсоров).

## DiscoveryView

| Элемент | Поведение |
|---------|-----------|
| `icon` | `antenna.radiowaves.left.and.right`, `.symbolEffect(.variableColor)` пока список пуст |
| `searching` | Показывается, если `servers.isEmpty` |
| `serverList` | Карточки `ServerCard` с `name`, `host:port`, кнопкой «Подключиться» |

Входы: `servers: [DiscoveredServer]`, `onConnect: (DiscoveredServer) -> Void`.

`ServerCard` — private struct внутри файла, не используется снаружи.

## MotionHUDView

| Элемент | Поведение |
|---------|-----------|
| `connectionBadge` | Точка (зелёная при `isConnected`) + `host:port` моноширинно |
| `readout` | Три секции: «Поворот», «Гравитация», «Ускорение» по 3 строки X/Y/Z |
| `row(label, value, unit, decimals)` | Используется `.contentTransition(.numericText)` — плавная анимация смены цифр |
| `unavailable` | Если `motion.isAvailable == false` (превью / не iOS) |
| `disconnectButton` | Зовёт `onDisconnect` |

Входы: `motion: MotionManager`, `server: DiscoveredServer`, `isConnected: Bool`, `onDisconnect: () -> Void`.

## Зависимости
- Использует: SwiftUI, [[api/discovered-server]], [[modules/ios-motion]] (через ссылку на `MotionManager`)
- Используется в: [[modules/ios-app]] (`ContentView` свитчит между этими двумя View по [[api/app-state]])

## Важные детали
- UI рассчитан на **светлую тему** (`preferredColorScheme(.light)` в `ContentView`). Цвета прописаны как `Color.black.opacity(…)` / `Color.white`.
- Локализация — русский inline в строках (`"Поиск сервера…"`, `"Подключиться"`, `"Поворот"`, `"Гравитация"`, `"Ускорение"`, `"Отключиться"`, `"Датчики недоступны"`).
- HUD читает значения **через keypath**, а не через колбэк — `MotionManager` сам `@Observable`, SwiftUI перерисовывает строки.
- `formatted(value:decimals:)` в HUD использует `String(format: "%+.\(decimals)f", ...)` — знак всегда есть.
