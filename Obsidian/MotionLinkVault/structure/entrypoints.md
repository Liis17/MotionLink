# Точки входа

Parent: [[structure/overview]]

## iOS

**`ios/MotionLink/MotionLinkApp.swift`**
- `@main struct MotionLinkApp: App` — точка входа SwiftUI-приложения.
- Создаёт `ModelContainer` для SwiftData (хранит схему с одним классом `Item` — артефакт шаблона Xcode, не используется в логике).
- В `WindowGroup` показывает [[modules/ios-ui]] → `ContentView`.

Дальше управление переходит к `ContentView` ([[modules/ios-app]]), который держит `@State` для трёх сервисов (`MotionManager`, `DiscoveryService`, `MotionSender`) и переключает экран по `AppState` ([[api/app-state]]).

## Android

**`android/app/src/main/AndroidManifest.xml`**
- Permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`.
- `MainActivity` (`.MainActivity`) с launcher `<intent-filter>` — `MAIN` / `LAUNCHER`.

**`android/app/src/main/java/com/barkfluff/motionlink/MainActivity.kt`**
- `class MainActivity : ComponentActivity()`.
- `enableEdgeToEdge()` + `setContent { MotionLinkApp() }`.

Корневой `@Composable` — `MotionLinkApp()` ([[modules/android-app]]), который держит `remember`-singletons (`DiscoveryService`, `MotionManager`, `MotionSender`) и переключает экраны по [[api/app-state]] (используется тот же state-машинный концепт, что и в iOS).

См. [[modules/android-app]].
