# Android MotionManager

Parent: [[modules/android-app]]

## Файл
`android/app/src/main/java/com/barkfluff/motionlink/motion/MotionManager.kt`

## Что делает
Слушает сенсоры через `SensorManager`, собирает срезы в [[api/motion-snapshot]] на тикере 30 Гц и публикует через `StateFlow<MotionSnapshot?>` (для HUD) + опциональный callback (для [[modules/android-sender]]).

## Источники

| Поле snapshot | Sensor | Единицы у Android | Преобразование |
|---|---|---|---|
| `roll`, `pitch`, `yaw` | `TYPE_ROTATION_VECTOR` | unit quaternion | `getRotationMatrixFromVector` → `getOrientation` → `Math.toDegrees` |
| `acceleration` | `TYPE_LINEAR_ACCELERATION` | м/с² | `/ 9.80665` → g |
| `gravity` | `TYPE_GRAVITY` | м/с² | `/ 9.80665` → g |
| `rotationRate` | `TYPE_GYROSCOPE` | рад/с | без преобразования |

## ROTATION_VECTOR → углы Эйлера

`SensorManager.getOrientation(R, out)` возвращает:
- `out[0]` — azimuth (yaw, вокруг -Z) — **абсолютный** относительно магнитного севера (зависит от компаса)
- `out[1]` — pitch (вокруг X)
- `out[2]` — roll (вокруг Y)

⚠️ В отличие от iOS (`CMAttitudeReferenceFrame.xArbitraryZVertical`), Android yaw — компасный, не относительный. Поведение немного разойдётся с iOS: yaw на старте не нулевой.

## Темп

- Регистрация сенсоров с `SensorManager.SENSOR_DELAY_GAME` (≈50 Гц).
- Отдельный coroutine job на `Dispatchers.Default` тикает `delay(33L)` ≈ 30 Гц и:
  1. Берёт последние значения из `@Volatile`-полей.
  2. Пересчитывает orientation из `rotationVector`.
  3. Собирает `MotionSnapshot`.
  4. Публикует в `_latest` и зовёт `onUpdate`.

`@Volatile` достаточно — сенсорные callback'и пишут только целые `FloatArray`, тикер читает их «как есть». Точная синхронизация компонент не нужна — все 30 раз/сек кадр консистентен «на глаз».

## API
```kotlin
class MotionManager(context: Context) {
    val latest: StateFlow<MotionSnapshot?>
    fun start(onUpdate: ((MotionSnapshot) -> Unit)? = null)
    fun stop()
}
```

## Жизненный цикл
- `start()` идемпотентен.
- `stop()` отменяет job, снимает все `registerListener`, обнуляет `_latest`.
- При сворачивании приложения (`onPause` Activity) Android может приостановить сенсоры — `keepScreenOn` в HUD (см. [[modules/android-ui]]) уменьшает вероятность.

## Связанное
- [[modules/ios-motion]] — iOS-аналог (CoreMotion `attitude/userAcceleration/gravity/rotationRate`)
- [[api/motion-snapshot]]
- [[modules/protocol]] § Поток данных
