# Android App — общая сборка

Parent: [[index]]

## Назначение
Android-клиент MotionLink. Зеркало iOS-клиента: discovery → выбор сервера → стриминг данных датчиков по UDP. UI на Jetpack Compose.

## Точка входа

`android/app/src/main/java/com/barkfluff/motionlink/MainActivity.kt`

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(s: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(s)
        setContent { MotionLinkApp() }
    }
}
```

`enableEdgeToEdge()` нужен для прозрачных system bars (см. тему `Theme.MotionLink`).

## Корневой `@Composable`

`MotionLinkApp.kt`:
- Создаёт singletons `DiscoveryService`, `MotionManager`, `MotionSender` через `remember`.
- Хранит `AppState` в `mutableStateOf` (см. [[api/app-state]]).
- Подписывается на `StateFlow`-и сервисов через `collectAsStateWithLifecycle`.
- `DisposableEffect(state)` управляет жизненным циклом сервисов: запускает/останавливает discovery vs. motion+sender.
- `AnimatedContent` переключает `DiscoveryScreen` ↔ `MotionHUDScreen` с fade-переходом.

### Важная деталь — захват состояния в DisposableEffect

`onDispose` использует **захваченную** локальную переменную `active`, а не `state`. Иначе при переходе Searching→Streaming в onDispose уже видно новое состояние, и cleanup делается не по тому branche.

```kotlin
DisposableEffect(state) {
    val active = state  // ← снимок до перехода
    when (active) { ... start ... }
    onDispose {
        when (active) { ... stop ... }
    }
}
```

## Тема

`ui/Theme.kt` — `MotionLinkTheme` с динамическими цветами (`dynamicLightColorScheme` / `dynamicDarkColorScheme`) на Android 12+. На старых API fallback на статичные палитры.

`res/values/themes.xml` и `values-night/themes.xml` — `Theme.Material3.DayNight.NoActionBar` с прозрачными system bars. Активити использует эту тему как базовую, чтобы splash и edge-to-edge выглядели нативно.

## Манифест

`AndroidManifest.xml`:
- `INTERNET` — обязательно для DatagramSocket.
- `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` — для будущей диагностики Wi-Fi.
- `CHANGE_WIFI_MULTICAST_STATE` — нужно для `WifiManager.MulticastLock`, без которого некоторые роутеры/девайсы не доставляют broadcast (см. [[modules/android-discovery]]).
- `uses-feature` для accelerometer + gyroscope — обязательны; compass — рекомендован (для абсолютного yaw).
- `MainActivity` с launcher-intent-filter, `configChanges` чтобы при ротации не пересоздавалась Activity.

## Сборка

`app/build.gradle.kts`:
- Плагины: `com.android.application`, `kotlin.compose`.
- **Kotlin Android plugin (`org.jetbrains.kotlin.android`) НЕ применяется** — AGP 9 имеет built-in Kotlin support и сам регистрирует `kotlin {}` extension. Попытка применить `kotlin.android` параллельно даёт `Cannot add extension with name 'kotlin', as there is an extension already registered`. Подробнее: [[changelog/2026-05-17]] § Инцидент сборки.
- `kotlin.compose` — это compose compiler plugin (Kotlin 2.x), он только добавляет compose compiler в существующую Kotlin-компиляцию, новый `kotlin {}` extension не создаёт → не конфликтует.
- `buildFeatures.compose = true`.
- compileSdk 36 (minorApiLevel 1), minSdk 35, targetSdk 36, Java 11.
- Зависимости: Compose BOM, Material3, activity-compose, lifecycle-runtime-compose, kotlinx-coroutines-android. AppCompat и Material View оставлены — пока не вычищены, но Compose-экранам не нужны.

## Связанное

- [[modules/android-discovery]]
- [[modules/android-motion]]
- [[modules/android-sender]]
- [[modules/android-ui]]
- [[api/app-state]]
- [[modules/protocol]]
