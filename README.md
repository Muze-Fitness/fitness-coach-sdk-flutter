# Zing Fitness Coach SDK (Flutter)

Flutter plugin that wires the native Zing SDK configuration on Android and iOS through a single Dart-facing API. The plugin makes sure the Android SDK is initialized exactly once and exposes a unified logout call for clearing native state.

## Requirements

| Requirement                | Value / Notes                           |
| -------------------------- | --------------------------------------- |
| Minimum Android version    | 8.0 (API 26)                            |
| Compile SDK                | 34+ (tested with 36)                    |
| Flutter                    | 3.3.0 or newer                          |
| Dependency injection       | Hilt (`com.google.dagger:hilt-android`) |
| Maven credentials          | GitHub Packages Access Token            |

## Installing the Flutter plugin

Add the Git dependency to your `pubspec.yaml` (the plugin is distributed privately and is not published on pub.dev):

```yaml
dependencies:
  zing_sdk_initializer:
    git:
      url: https://github.com/Muze-Fitness/fitness-coach-sdk-flutter.git
```

Then run `flutter pub get` to fetch the dependency.

## Installation & Setup (Android)

To successfully integrate this plugin on Android, you must configure your project to support the native Zing SDK dependencies (Hilt, Github Packages).

### 1. Add Maven Repository & Credentials
The native SDK is hosted on GitHub Packages. Add the repository to your `android/build.gradle` (or `settings.gradle`):

```gradle
maven {
    url = uri("https://maven.pkg.github.com/Muze-Fitness/fitness-coach-sdk-android")
    
    // Optional: explicit local.properties loading if not handled by parent build
    val localProperties = java.util.Properties()
    val localPropertiesFile = File(rootDir, "local.properties")
    if (localPropertiesFile.exists()) {
        localProperties.load(localPropertiesFile.inputStream())
    }
    
    credentials {
        username = localProperties.getProperty("zing_sdk_username")
        password = localProperties.getProperty("zing_sdk_token")
    }
}
```

Ensure you provide a valid GitHub Personal Access Token via `local.properties`.

### 2. Configure Hilt (choose KSP or KAPT)
The SDK uses Hilt for dependency injection. Add the Hilt plugin at the project level and pick the annotation processor style your app already relies on.

- **Option A — KSP (recommended)**  
  *Project-level (`android/build.gradle` or `settings.gradle`):*
  ```kotlin
  id("com.google.dagger.hilt.android") version "2.56.1" apply false
  id("com.google.devtools.ksp") version "2.1.20-2.0.0" apply false
  ```
  *App module (`android/app/build.gradle`):*
  ```kotlin
  plugins {
      id("com.google.devtools.ksp")
      id("com.google.dagger.hilt.android")
  }

  dependencies {
      implementation("com.google.dagger:hilt-android:2.56.1")
      ksp("com.google.dagger:hilt-android-compiler:2.56.1")
  }
  ```

- **Option B — KAPT (legacy projects)**  
  *Project-level (`android/build.gradle` or `settings.gradle`):*
  ```kotlin
  id("com.google.dagger.hilt.android") version "2.56.1" apply false
  ```
  *App module (`android/app/build.gradle`):*
  ```kotlin
  plugins {
      kotlin("kapt")
      id("com.google.dagger.hilt.android")
  }

  dependencies {
      implementation("com.google.dagger:hilt-android:2.56.1")
      kapt("com.google.dagger:hilt-android-compiler:2.56.1")
  }
  ```

### 3. Custom Application Class
Create a custom `Application` class extending `SdkApplication` and annotate it with `@HiltAndroidApp`:

```kotlin
import coach.zing.fitness.coach.SdkApplication
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class MyApplication : SdkApplication() {
    override fun onCreate() {
        super.onCreate()
    }
}
```

Don't forget to register it in `AndroidManifest.xml`:
```xml
<application
    android:name=".MyApplication"
    ... >
```

### 4. Minimum SDK Version
Set `minSdk` to **26** (Android 8.0) or higher in `android/app/build.gradle`.

### 5. Update MainActivity
Change your `MainActivity` to inherit from `FlutterFragmentActivity`. This is required for proper Hilt and Fragment support used by the SDK. Also add @AndroidEntryPoint annotation to you activity.

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

@AndroidEntryPoint
class MainActivity : FlutterFragmentActivity()
```

### 6. Disable the default WorkManager initializer
Add the following provider override to your app `AndroidManifest.xml` (inside `<application>`). This removes the default WorkManager initializer that conflicts with the SDK startup logic.

```xml
<provider
    android:name="androidx.startup.InitializationProvider"
    android:authorities="${applicationId}.androidx-startup"
    android:exported="false"
    tools:node="merge">

    <meta-data
        android:name="androidx.work.WorkManagerInitializer"
        android:value="androidx.startup"
        tools:node="remove" />
</provider>
```

### 7. Health Connect Integration (Optional)

To enable Health Connect synchronization, add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

To restart health sync after device reboot, register the boot receiver inside `<application>`:

```xml
<receiver
    android:name="coach.zing.fitness.coach.broadcast.SdkHealthSyncBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

## Flutter API

```dart
// Initialize the SDK
await ZingSdkInitializer.instance.initialize();

// Logout
await ZingSdkInitializer.instance.logout();

// Open a native screen directly from Flutter (requires initialize())
await ZingSdkInitializer.instance.openScreen(ZingSdkScreen.aiAssistant);
```

- `initialize()` is idempotent and only forwards to the native SDK the first
  time it is called per process.
- `logout()` clears the native SDK state (databases, cached workouts, auth
  state)
- `openScreen()` launches one of the supported native screens
  inside the SDK (`customWorkout`, `aiAssistant`, `workoutPlanDetails`,
  `fullSchedule`, `profileSettings`, `healthConnectPermissions`)

### UI Components

The plugin provides a wrapper widget for the native Workout Plan Card:

```dart
import 'package:zing_sdk_initializer/workout_plan_card_view.dart';

// ...

Expanded(
  child: WorkoutPlanCardHost(
    unsupportedPlaceholder: Center(child: Text('Not supported')),
  )
)
```

## Example app

An example Flutter application is available under `example/`. It showcases:

- Initializing the native SDK from Flutter before rendering the UI.
- Displaying the Compose-based `WorkoutPlanCard` platform view on Android.

To run the demo:

1. Ensure `example/android/local.properties` contains your Maven credentials (see [Step 1](#1-add-maven-repository--credentials)).
2. Run the app:

```bash
cd example
flutter pub get
flutter run
```
