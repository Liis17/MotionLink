# iOS Motion — чтение датчиков

Parent: [[index]]

## Назначение
Читает CoreMotion `deviceMotion` 30 раз в секунду, конвертирует углы из радиан в градусы, публикует значения для UI и зовёт колбэк `onUpdate` с готовым `MotionSnapshot` для отправки.

## Файлы
- `ios/MotionLink/MotionManager.swift` — `MotionManager` + struct `MotionSnapshot`.

## Тип
`@Observable final class MotionManager`

Publish-state (для HUD):
- `roll, pitch, yaw: Double` — углы в **градусах**
- `accelerationX/Y/Z: Double` — g, без гравитации
- `gravityX/Y/Z: Double` — g
- `rotationRateX/Y/Z: Double` — рад/с
- `isAvailable: Bool`

`@ObservationIgnored`:
- `manager: CMMotionManager`
- `timer: Timer?`
- `onUpdate: ((MotionSnapshot) -> Void)?`

## Ключевые методы
| Метод | Описание |
|-------|----------|
| `start()` | Проверяет `isDeviceMotionAvailable`, ставит `deviceMotionUpdateInterval = 1/60`, запускает `Timer` 30 Гц |
| `stop()` | Инвалидирует таймер, `stopDeviceMotionUpdates()` |
| `tick()` *(private)* | Берёт `manager.deviceMotion`, конвертит rad→deg, пушит в @Observable свойства, формирует `MotionSnapshot`, зовёт `onUpdate` |

## Зависимости
- Использует: `CoreMotion` (только на iOS, обёрнуто в `#if os(iOS)`), `Observation`
- Производит: `MotionSnapshot` → [[api/motion-snapshot]]
- Используется в: [[modules/ios-app]] (ContentView), [[modules/ios-ui]] (HUD читает свойства)

## Важные детали
- **Два разных интервала:** CoreMotion обновляется на 60 Гц (`updateInterval = 1/60`), а наш Timer тикает 30 Гц — мы читаем последний доступный snapshot, не дожидаясь нового апдейта от CoreMotion.
- `tick()` использует `manager.deviceMotion` (snapshot-доступ), а не `startDeviceMotionUpdates(to:withHandler:)`. Это упрощает синхронизацию, но добавляет ~16 мс задержки.
- `t` пакета = `Date().timeIntervalSince1970` на момент `tick()`, **не** время самого замера CoreMotion (`motion.timestamp` не используется).
- На non-iOS (превью на Mac) весь блок отключен `#if os(iOS)` — `isAvailable` остаётся `false`.
- UI ожидает `isAvailable`, иначе показывает `unavailable` (см. [[modules/ios-ui]]).

## Связанное
- [[api/motion-snapshot]] — структура пакета
- [[structure/data-flow]] — куда идут данные дальше
