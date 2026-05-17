# AppState

Parent: [[index]]

## Где определено
`ios/MotionLink/ContentView.swift`

```swift
enum AppState: Equatable {
    case searching
    case streaming(DiscoveredServer)
}
```

## Семантика
Конечный автомат верхнего уровня для всего приложения.

```
.searching ──connect(to:)──▶ .streaming(server)
   ▲                                  │
   └────────disconnect()──────────────┘
```

## Переходы

| Из | Триггер | В | Что происходит |
|----|---------|---|----------------|
| `.searching` | `DiscoveryView` onConnect | `.streaming(server)` | `ContentView.connect(to:)`: discovery.stop, sender.start, motion.start, onUpdate=sender.send |
| `.streaming(_)` | `MotionHUDView` onDisconnect | `.searching` | `ContentView.disconnect()`: motion.stop, sender.stop, discovery.start |
| любое | View `.onDisappear` | (не меняется) | `teardown()` — гасит всё |

## Производный `stateID: Int`
`ContentView.stateID` — 0/1, нужно как ключ для `.animation(.smooth, value:)`, чтобы переход между экранами был анимирован, а изменения внутри одного экрана — нет.

## Связанное
- [[modules/ios-app]] — реализация переходов
- [[api/discovered-server]] — payload состояния `.streaming`
