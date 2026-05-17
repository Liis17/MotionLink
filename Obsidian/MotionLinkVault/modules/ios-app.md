# iOS App — координация

Parent: [[index]]

## Назначение
Корневой слой iOS-клиента: точка входа `@main`, корневая View, состояние приложения, склейка трёх сервисов (motion / discovery / sender).

## Файлы
- `ios/MotionLink/MotionLinkApp.swift` — `@main`, `WindowGroup { ContentView() }`, поднимает SwiftData-`ModelContainer`.
- `ios/MotionLink/ContentView.swift` — корневая View, держит `AppState`, делает connect/disconnect/teardown.
- `ios/MotionLink/Item.swift` — пустая SwiftData-модель (`@Model class Item { var timestamp: Date }`). **Артефакт шаблона Xcode**, по бизнес-логике не используется.

## Ключевые методы
| Метод | Описание |
|-------|----------|
| `MotionLinkApp.body` | Сцена `WindowGroup`, навешивает `.modelContainer` |
| `ContentView.body` | Свитч по `AppState`: показывает `DiscoveryView` или `MotionHUDView` |
| `ContentView.connect(to:)` | discovery.stop → sender.start → motion.onUpdate=sender.send → motion.start → state=.streaming |
| `ContentView.disconnect()` | motion.stop → sender.stop → discovery.start → state=.searching |
| `ContentView.teardown()` | Полный stop всего при `.onDisappear` |

`AppState` — см. [[api/app-state]].

## Зависимости
- Использует: [[modules/ios-discovery]], [[modules/ios-motion]], [[modules/ios-sender]], [[modules/ios-ui]]
- Используется: вызывается системой как `@main`

## Важные детали
- Все три сервиса хранятся как `@State` (Swift 5.9+ `@Observable` + `@State` — рекомендуемый способ).
- `Item` / SwiftData оставлены из шаблона; **не** удалять бездумно — `ModelContainer` создаётся в `MotionLinkApp`, и `fatalError` при сбое уронит приложение. Если убираете `Item`, уберите и `Schema`+`ModelContainer`.
- `preferredColorScheme(.light)` зафиксирован — UI рассчитан только на светлую тему.
