# MotionSnapshot

Parent: [[index]]

## Где определено
`ios/MotionLink/MotionManager.swift`

```swift
struct MotionSnapshot: Codable, Sendable {
    var t: Double
    var roll: Double
    var pitch: Double
    var yaw: Double
    var acceleration: Vector3
    var gravity: Vector3
    var rotationRate: Vector3

    struct Vector3: Codable, Sendable {
        var x: Double
        var y: Double
        var z: Double
    }
}
```

## Поля

| Поле | Тип | Единица | Источник CoreMotion |
|------|-----|---------|---------------------|
| `t` | `Double` | сек с Unix epoch | `Date().timeIntervalSince1970` |
| `roll` | `Double` | **градусы** | `attitude.roll * 180/π` |
| `pitch` | `Double` | градусы | `attitude.pitch * 180/π` |
| `yaw` | `Double` | градусы | `attitude.yaw * 180/π` |
| `acceleration` | `Vector3` | **g** | `userAcceleration` (без гравитации) |
| `gravity` | `Vector3` | g | `gravity` |
| `rotationRate` | `Vector3` | **рад/с** | `rotationRate` |

## JSON-сериализация
Кодируется в [[modules/ios-sender]] через `JSONEncoder` без `outputFormatting` → компактный JSON, ключи в порядке свойств struct'а.

Пример пакета — в [[modules/protocol]].

## Важные детали
- `Codable, Sendable` — структуру можно безопасно проносить через `@Sendable`-замыкания.
- `Vector3` — вложенный namespace, не путать с возможным глобальным `Vector3` из других фреймворков.
- Поля **не** опциональные — всегда заполняются в `MotionManager.tick()`.

## Связанное
- [[modules/ios-motion]] — где формируется
- [[modules/ios-sender]] — где сериализуется
- [[modules/protocol]] — wire-контракт
