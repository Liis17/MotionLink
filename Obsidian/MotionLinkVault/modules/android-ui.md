# Android UI (Compose)

Parent: [[modules/android-app]]

## Файлы
- `android/app/src/main/java/com/barkfluff/motionlink/ui/Theme.kt` — `MotionLinkTheme`, динамические цвета (Material You).
- `android/app/src/main/java/com/barkfluff/motionlink/ui/DiscoveryScreen.kt` — экран поиска сервера.
- `android/app/src/main/java/com/barkfluff/motionlink/ui/MotionHUDScreen.kt` — экран стрима с показом значений.

## DiscoveryScreen

Параметры:
```kotlin
@Composable
fun DiscoveryScreen(
    servers: List<DiscoveredServer>,
    onConnect: (DiscoveredServer) -> Unit,
)
```

- Заголовок «MotionLink» + sub-text с `CircularProgressIndicator` (вечно крутится — discovery без таймаута).
- Если `servers.isEmpty()` — `EmptyState` с иконкой `WifiOff` и подсказкой про Wi-Fi.
- Иначе `LazyColumn` с `ServerCard`-ами: имя сервера (или «Сервер» если nil), `host:port`, кнопка «Подключиться».

## MotionHUDScreen

Параметры:
```kotlin
@Composable
fun MotionHUDScreen(
    server: DiscoveredServer,
    snapshot: MotionSnapshot?,
    senderState: MotionSender.State,
    onDisconnect: () -> Unit,
)
```

Секции (`SectionCard`):
1. **Ориентация (°)** — roll / pitch / yaw, моноширинный шрифт, формат `%+8.2f`.
2. **Гравитация (g)** — x/y/z.
3. **Ускорение (g, без g)** — x/y/z из `userAcceleration`/`TYPE_LINEAR_ACCELERATION`.
4. **Угловая скорость (рад/с)** — x/y/z gyro.

`ConnectionBadge` — точка-индикатор + надпись `stream → host:port`. Цвет:
- зелёный → `Ready`
- красный → `Failed`
- серый → `Idle`

Внизу красная кнопка «Отключиться» (`onDisconnect`).

## KeepScreenOn

`KeepScreenOn()` — внутренний `@Composable` в `MotionHUDScreen.kt`. Достаёт `Activity` из `LocalContext` через walk `ContextWrapper`, ставит `FLAG_KEEP_SCREEN_ON` на `Window`. `DisposableEffect.onDispose` снимает флаг. Активен только пока виден HUD-экран.

## Тема

`MotionLinkTheme`:
- Android 12+ (`Build.VERSION_CODES.S`): `dynamicLightColorScheme(context)` / `dynamicDarkColorScheme(context)` — берёт цвета из обоев пользователя (Material You).
- Старее: статичные `LightColors` / `DarkColors` (синий + голубой акцент).
- Реагирует на `isSystemInDarkTheme()`.

## Связанное

- [[modules/ios-ui]] — SwiftUI-аналог (`DiscoveryView`, `MotionHUDView`)
- [[api/app-state]] — состояние, между которыми переключаются экраны
- [[api/discovered-server]], [[api/motion-snapshot]]
