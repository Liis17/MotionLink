# MotionLink — Project Index

> Главная точка входа в документацию проекта. Создано: 2026-05-17. Обновлено: 2026-05-17 (PROTOCOL.md перенесён в корень, добавлен README.md).

## О проекте

**MotionLink** — клиентское приложение для трансляции данных датчиков движения с телефона на локальный UDP-сервер.

- **iOS-клиент** (реализован): SwiftUI-приложение, читает CoreMotion (attitude / userAcceleration / gravity / rotationRate), находит сервер в LAN через UDP-broadcast и шлёт ~30 пакетов JSON в секунду.
- **Android-клиент** (реализован 2026-05-17): Jetpack Compose + SensorManager + DatagramSocket, тот же UDP-протокол. Namespace `com.barkfluff.motionlink`.
- **Протокол** клиент → сервер — UDP, полностью описан в `PROTOCOL.md`. См. [[modules/protocol]].

## Быстрая навигация

### 🏗 Архитектура
- [[structure/overview]] — общая структура репозитория
- [[structure/entrypoints]] — точки входа (iOS app, Android manifest)
- [[structure/data-flow]] — поток данных от сенсора до сокета

### 📦 Модули
- [[modules/protocol]] — wire-протокол UDP (discovery + поток данных)

**iOS-клиент**
- [[modules/ios-app]] — общая сборка SwiftUI-приложения
- [[modules/ios-discovery]] — поиск сервера по UDP-broadcast
- [[modules/ios-motion]] — чтение сенсоров (CoreMotion)
- [[modules/ios-sender]] — отправка пакетов на сервер (NWConnection)
- [[modules/ios-ui]] — UI-слой (DiscoveryView, MotionHUDView)

**Android-клиент**
- [[modules/android-app]] — общая сборка Compose-приложения
- [[modules/android-discovery]] — DatagramSocket + MulticastLock discovery
- [[modules/android-motion]] — SensorManager (RotationVector + LinearAccel + Gravity + Gyro)
- [[modules/android-sender]] — DatagramSocket UDP-отправка
- [[modules/android-ui]] — Compose-экраны (DiscoveryScreen, MotionHUDScreen)

### 🔧 API & Методы
- [[api/motion-snapshot]] — структура `MotionSnapshot` (JSON-payload)
- [[api/discovered-server]] — `DiscoveredServer` и идентификация сервера
- [[api/app-state]] — конечный автомат `AppState` (searching ↔ streaming)

### 📋 Изменения
- [[changelog/2026-05-18]] — ручной ввод адреса сервера в iOS как fallback для broadcast-discovery
- [[changelog/2026-05-17]] — реализация Android-клиента, перенос PROTOCOL.md в корень, добавление README.md

## Стек технологий

| Слой | iOS | Android |
|------|-----|---------|
| Язык | Swift 5 (`@Observable`) | Kotlin 2.1 (`StateFlow` + coroutines) |
| UI | SwiftUI | Jetpack Compose + Material 3 |
| Сенсоры | CoreMotion (`CMMotionManager`) | `SensorManager` (`TYPE_ROTATION_VECTOR`, `TYPE_LINEAR_ACCELERATION`, `TYPE_GRAVITY`, `TYPE_GYROSCOPE`) |
| Сеть | `Network.framework` (`NWConnection`) + raw POSIX `socket(AF_INET, SOCK_DGRAM)` для broadcast | `java.net.DatagramSocket` + `WifiManager.MulticastLock` |
| Хранение | SwiftData (Item, не используется по делу) | — |
| Сборка | Xcode 16 (`MotionLink.xcodeproj`) | Gradle Kotlin DSL, AGP 9.2.1, compileSdk 36, minSdk 35 |

## Ключевые файлы

| Файл | Назначение |
|------|------------|
| `README.md` | Краткое описание проекта (что собирает, формат JSON, как находит сервер) |
| `PROTOCOL.md` | Полная спецификация UDP-протокола клиент ↔ сервер (общая для iOS и Android) |
| `ios/MotionLink/MotionLink.entitlements` | Разрешения сети iOS (`network.client` + `network.server`) — нужно для UDP-broadcast |
| `ios/MotionLink/MotionLinkApp.swift` | `@main` входная точка iOS |
| `ios/MotionLink/ContentView.swift` | Корневая View, `AppState` (searching / streaming) |
| `ios/MotionLink/DiscoveryService.swift` | UDP-broadcast discovery, POSIX-сокет |
| `ios/MotionLink/MotionManager.swift` | Чтение CoreMotion, формирование `MotionSnapshot` |
| `ios/MotionLink/MotionSender.swift` | UDP-отправка JSON через `NWConnection` |
| `ios/MotionLink/DiscoveryView.swift` | Экран поиска сервера |
| `ios/MotionLink/MotionHUDView.swift` | Экран показа значений сенсоров во время стрима |
| `android/app/src/main/java/com/barkfluff/motionlink/MainActivity.kt` | Точка входа Android, `setContent { MotionLinkApp() }` |
| `android/app/src/main/java/com/barkfluff/motionlink/MotionLinkApp.kt` | Корневой `@Composable`, `AppState`-навигация |
| `android/app/src/main/java/com/barkfluff/motionlink/discovery/DiscoveryService.kt` | UDP-broadcast discovery |
| `android/app/src/main/java/com/barkfluff/motionlink/motion/MotionManager.kt` | SensorManager + 30 Гц тикер |
| `android/app/src/main/java/com/barkfluff/motionlink/motion/MotionSender.kt` | DatagramSocket UDP-отправка |
| `android/app/src/main/java/com/barkfluff/motionlink/ui/DiscoveryScreen.kt` | Compose-экран поиска |
| `android/app/src/main/java/com/barkfluff/motionlink/ui/MotionHUDScreen.kt` | Compose-HUD стрима |
| `android/app/src/main/AndroidManifest.xml` | Permissions (INTERNET, MULTICAST) + MainActivity launcher |
