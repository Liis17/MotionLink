# Структура проекта

Parent: [[index]]

## Дерево директорий

```
MotionLink/
├── README.md                    ← краткое описание проекта для пользователя
├── PROTOCOL.md                  ← спека UDP-протокола (единый источник правды)
├── CLAUDE.md                    ← глобальные правила работы (память)
├── Obsidian/
│   └── MotionLinkVault/         ← этот vault
├── ios/                         ← iOS-клиент (реализован)
│   ├── MotionLink.xcodeproj/    ← Xcode-проект
│   └── MotionLink/              ← исходники Swift
│       ├── MotionLinkApp.swift          ← @main, ModelContainer (SwiftData)
│       ├── ContentView.swift            ← корневая View + AppState
│       ├── DiscoveryService.swift       ← UDP-broadcast discovery
│       ├── DiscoveryView.swift          ← UI поиска сервера
│       ├── MotionManager.swift          ← чтение CoreMotion
│       ├── MotionSender.swift           ← UDP-отправка пакетов
│       ├── MotionHUDView.swift          ← UI стрима (HUD значений)
│       ├── Item.swift                   ← пустой SwiftData-модель (артефакт шаблона Xcode)
│       ├── MotionLink.entitlements      ← разрешения сети
│       └── Assets.xcassets/
└── android/                     ← Android-клиент (Kotlin + Compose)
    ├── build.gradle.kts                 ← top-level (kotlin.android, kotlin.compose плагины)
    ├── settings.gradle.kts
    ├── gradle.properties
    ├── local.properties
    ├── gradle/                          ← wrapper + libs.versions.toml
    └── app/
        ├── build.gradle.kts             ← namespace com.barkfluff.motionlink + Compose BOM
        ├── proguard-rules.pro
        └── src/
            ├── main/
            │   ├── AndroidManifest.xml  ← permissions + MainActivity launcher
            │   ├── res/                 ← иконки, strings, Material3-темы
            │   └── java/com/barkfluff/motionlink/
            │       ├── MainActivity.kt
            │       ├── MotionLinkApp.kt          ← корневой @Composable
            │       ├── model/                    ← AppState, DiscoveredServer, MotionSnapshot
            │       ├── discovery/DiscoveryService.kt
            │       ├── motion/                   ← MotionManager, MotionSender
            │       └── ui/                       ← Theme, DiscoveryScreen, MotionHUDScreen
            ├── test/                    ← ExampleUnitTest.kt (шаблон)
            └── androidTest/             ← ExampleInstrumentedTest.kt (шаблон)
```

## Описание директорий

### `/ios`
iOS-клиент. Полностью функциональный. Содержит реализацию Swift; спецификация протокола вынесена в `PROTOCOL.md` в корне репозитория (т.к. она общая для iOS и Android).

### `/ios/MotionLink`
Все swift-исходники приложения. Разделены по ответственностям:
- сетевой слой: [[modules/ios-discovery]], [[modules/ios-sender]]
- сенсорный слой: [[modules/ios-motion]]
- UI: [[modules/ios-ui]]
- координация: [[modules/ios-app]]

### `/android`
Android-клиент на Kotlin + Jetpack Compose. Зеркало iOS-клиента: discovery → выбор сервера → стриминг данных датчиков по UDP. Разделение по ответственностям:
- сетевой слой: [[modules/android-discovery]], [[modules/android-sender]]
- сенсорный слой: [[modules/android-motion]]
- UI: [[modules/android-ui]]
- координация: [[modules/android-app]]

### `/Obsidian`
Vault с памятью проекта (этот). Не относится к сборке.

## Конфигурационные файлы

| Файл | Назначение |
|------|-----------|
| `README.md` | Краткое описание проекта: что собирает, формат JSON, как находит сервер |
| `PROTOCOL.md` | Полная спецификация UDP-протокола, общая для iOS и Android |
| `ios/MotionLink/MotionLink.entitlements` | `com.apple.security.network.client`, `network.server`, `app-sandbox` — нужно для UDP-broadcast |
| `ios/MotionLink.xcodeproj/project.pbxproj` | Xcode-конфигурация iOS-таргета |
| `android/build.gradle.kts` | Подключает Android Application + Kotlin + Compose плагины |
| `android/app/build.gradle.kts` | `compileSdk 36`, `minSdk 35`, namespace `com.barkfluff.motionlink`, Compose BOM + Material3 |
| `android/gradle/libs.versions.toml` | Каталог версий: AGP 9.2.1, Kotlin 2.1.20, Compose BOM 2025.06.01 |

## Связанное

- [[structure/entrypoints]] — какие файлы запускают приложение
- [[structure/data-flow]] — как данные идут от датчика до байтов в сокете
