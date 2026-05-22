cat > /home/claude/amol_widget_prompt.md << 'EOF'

# 📱 Amol Tracker — Android Home Screen Widget

# Implementation Prompt for Cursor

# Read every word before touching any file.

---

## Context

This is a Flutter app (amol_tracker_app) using:

- Flutter 3.38.3 / Dart 3.10.1
- Riverpod state management
- Firestore + Hive offline cache
- IslamicDateService (Maghrib-based, Bangladesh UTC+6)
- Feature-first folder structure: lib/features/

### Read these files BEFORE writing any code:

1. lib/models/amal_log_model.dart
2. lib/core/services/islamic_date_service.dart
3. lib/core/services/local_storage_service.dart
4. lib/core/constants/default_amal_fields.dart
5. lib/providers/amal_provider.dart
6. pubspec.yaml
7. android/app/src/main/AndroidManifest.xml

---

## What we are building

An **Android home screen widget** that shows the user's daily amal
progress directly on their phone's home screen — visible without
opening the app. This is the most effective reminder because it's
always passively visible.

**iOS Note:** iOS home screen widgets require a separate
implementation with WidgetKit (Swift). Do NOT implement iOS in this
prompt — Android only. Add a comment in the code marking where iOS
support should be added later.

---

## Package to use

Add `home_widget` package to pubspec.yaml:

```yaml
home_widget: ^0.6.0
```

This is the recommended Flutter package for home screen widgets.
It handles the Flutter ↔ native widget data bridge.

Run `flutter pub get` after adding.

---

## Widget design spec

### Widget size: medium (4×2 grid cells — standard Android medium widget)

### Visual layout:

```
┌─────────────────────────────────────────┐
│  🌙 আমল ট্র্যাকার    ১৫ শাওয়াল ১৪৪৭  │
│─────────────────────────────────────────│
│                                         │
│   ৭৪/১০০          ████████░░  ৭/৯      │
│   আজকের স্কোর      progress   আমল      │
│                                         │
│─────────────────────────────────────────│
│  🕌✅  📖✅  ☀️✅  🌙✅  📿⏳  🌟⏳  🪥❌ │
│─────────────────────────────────────────│
│         আমল লগ করো →                   │
└─────────────────────────────────────────│
```

### Three widget states:

**State 1 — Not logged yet (default, most important)**

- Background: dark emerald (#0D3D2E)
- Top: App name + today's Hijri date
- Middle: "আজ কোনো আমল লগ হয়নি"
- Bottom: Prominent gold CTA button "আমল লগ করো →"
- Subtle pulsing gold border (draws attention)

**State 2 — Partially logged (some amal done, not submitted)**

- Background: dark emerald
- Score: shows current draft score e.g. "৪৫/১০০"
- Progress bar: filled proportionally in gold
- Amal icons row: ✅ done, ⏳ pending
- CTA: "জমা দাও →"

**State 3 — Fully submitted**

- Background: slightly lighter emerald (#1A5C42)
- Score: shows final score with gold color "৭৪/১০০ ✓"
- Progress bar: fully or partially filled
- Amal icons row: ✅ done, ❌ missed
- Bottom text: "আলহামদুলিল্লাহ — আজকের আমল সম্পন্ন"
- No CTA button (already done)

### Colors (match app exactly):

```
Background:     #0D3D2E (emerald deep)
Background2:    #1A5C42 (emerald mid — for submitted state)
Gold:           #C9A84C
Gold light:     #E8C96A
Text primary:   #FFFFFF
Text muted:     #FFFFFF99
Success green:  #2ECC71
Danger red:     #E74C3C
Pending grey:   #FFFFFF40
```

---

## Implementation Plan

### Step 1 — Add home_widget package

In `pubspec.yaml`:

```yaml
dependencies:
  home_widget: ^0.6.0
```

Run `flutter pub get`.

---

### Step 2 — Create the widget data service

Create new file:
`lib/features/widget/home_widget_service.dart`

This service is responsible for pushing data from Flutter to the
native widget. It should be called:

- After every amal toggle change (draft update)
- After amal submission
- On app resume (in case data changed)
- When Islamic date changes (after Maghrib)

```dart
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String _appGroupId = 'com.sakib.amol_tracker_app';
  static const String _iOSWidgetName = 'AmolWidget'; // for future iOS
  static const String _androidWidgetName = 'AmolWidgetProvider';

  /// Call this after any amal state change or on app resume.
  /// Pushes all widget data and triggers a native widget refresh.
  static Future<void> updateWidget({
    required String hijriDate,         // e.g. "1447-10-15"
    required String hijriDateDisplay,  // e.g. "১৫ শাওয়াল ১৪৪৭"
    required int score,                // 0–100
    required int maxScore,             // kMaxDailyScore = 100
    required int completedCount,       // how many amal done
    required int totalCount,           // total amal = 9
    required bool isSubmitted,         // true after final submission
    required Map<String, dynamic> toggles,  // field id → bool/int
    required List<AmalField> fields,   // for icon mapping
  }) async {
    try {
      // Save all widget data to shared storage
      await HomeWidget.saveWidgetData('hijriDate', hijriDate);
      await HomeWidget.saveWidgetData('hijriDateDisplay', hijriDateDisplay);
      await HomeWidget.saveWidgetData('score', score);
      await HomeWidget.saveWidgetData('maxScore', maxScore);
      await HomeWidget.saveWidgetData('completedCount', completedCount);
      await HomeWidget.saveWidgetData('totalCount', totalCount);
      await HomeWidget.saveWidgetData('isSubmitted', isSubmitted);

      // Save each amal field state as individual keys
      // e.g. 'amal_fard' = '4' (numeric) or 'amal_morning_azkar' = 'true'
      for (final field in fields) {
        final value = toggles[field.id];
        if (field.type == AmalType.numeric) {
          final intVal = getNumericValue(value, field.maxValue);
          await HomeWidget.saveWidgetData('amal_${field.id}', intVal.toString());
        } else {
          await HomeWidget.saveWidgetData(
              'amal_${field.id}', (value == true).toString());
        }
      }

      // Trigger native widget refresh
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
        qualifiedAndroidName:
            'com.sakib.amol_tracker_app.$_androidWidgetName',
      );
    } catch (e) {
      // Widget update failure should never crash the app
      debugPrint('HomeWidgetService: update failed — $e');
    }
  }

  /// Call this on app cold start to handle widget tap deep link
  static Future<Uri?> getWidgetLaunchUri() async {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  /// Register callback for widget tap while app is in background
  static void registerInteractivityCallback() {
    HomeWidget.setAppGroupId(_appGroupId);
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        // Navigate to home screen
        // Use your existing router navigation here
        // e.g. router.go(AppRoutes.home)
      }
    });
  }
}
```

---

### Step 3 — Create Android widget layout files

Create these files in the Android layer:

#### File 1: android/app/src/main/res/layout/amol_widget.xml

This is the widget's visual layout in XML.
Use RemoteViews-compatible views only:

- LinearLayout, RelativeLayout, FrameLayout
- TextView, ImageView, ProgressBar
- No ConstraintLayout (not supported in widgets)

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/widget_background"
    android:padding="12dp">

    <!-- Header row: app name + date -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">

        <TextView
            android:id="@+id/widget_app_name"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="আমল ট্র্যাকার"
            android:textColor="#E8C96A"
            android:textSize="12sp"
            android:fontFamily="sans-serif-medium"/>

        <TextView
            android:id="@+id/widget_hijri_date"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="১৫ শাওয়াল ১৪৪৭"
            android:textColor="#FFFFFF99"
            android:textSize="10sp"/>
    </LinearLayout>

    <!-- Divider -->
    <View
        android:layout_width="match_parent"
        android:layout_height="0.5dp"
        android:background="#40C9A84C"
        android:layout_marginTop="6dp"
        android:layout_marginBottom="8dp"/>

    <!-- Score + progress row -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">

        <!-- Score text -->
        <LinearLayout
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:layout_marginEnd="12dp">

            <TextView
                android:id="@+id/widget_score"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="০/১০০"
                android:textColor="#E8C96A"
                android:textSize="20sp"
                android:fontFamily="serif"/>

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="স্কোর"
                android:textColor="#FFFFFF60"
                android:textSize="9sp"/>
        </LinearLayout>

        <!-- Progress bar + count -->
        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical">

            <ProgressBar
                android:id="@+id/widget_progress"
                style="?android:attr/progressBarStyleHorizontal"
                android:layout_width="match_parent"
                android:layout_height="6dp"
                android:progress="0"
                android:max="100"
                android:progressDrawable="@drawable/widget_progress_bar"
                android:layout_marginBottom="4dp"/>

            <TextView
                android:id="@+id/widget_count"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="০/৯ আমল"
                android:textColor="#FFFFFF60"
                android:textSize="9sp"/>
        </LinearLayout>
    </LinearLayout>

    <!-- Status message or amal icons -->
    <TextView
        android:id="@+id/widget_status"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="আজ কোনো আমল লগ হয়নি"
        android:textColor="#FFFFFF99"
        android:textSize="10sp"
        android:layout_marginTop="8dp"
        android:layout_marginBottom="4dp"/>

    <!-- CTA button -->
    <TextView
        android:id="@+id/widget_cta"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="আমল লগ করো →"
        android:textColor="#0D3D2E"
        android:background="@drawable/widget_button_bg"
        android:textSize="11sp"
        android:fontFamily="sans-serif-medium"
        android:gravity="center"
        android:padding="6dp"
        android:layout_marginTop="4dp"/>

</LinearLayout>
```

#### File 2: android/app/src/main/res/drawable/widget_background.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#0D3D2E"/>
    <corners android:radius="16dp"/>
    <stroke android:width="1dp" android:color="#40C9A84C"/>
</shape>
```

#### File 3: android/app/src/main/res/drawable/widget_button_bg.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#C9A84C"/>
    <corners android:radius="8dp"/>
</shape>
```

#### File 4: android/app/src/main/res/drawable/widget_progress_bar.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@android:id/background">
        <shape android:shape="rectangle">
            <solid android:color="#1AFFFFFF"/>
            <corners android:radius="3dp"/>
        </shape>
    </item>
    <item android:id="@android:id/progress">
        <clip>
            <shape android:shape="rectangle">
                <solid android:color="#C9A84C"/>
                <corners android:radius="3dp"/>
            </shape>
        </clip>
    </item>
</layer-list>
```

#### File 5: android/app/src/main/res/xml/amol_widget_info.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/amol_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:description="@string/widget_description"
    android:previewLayout="@layout/amol_widget">
</appwidget-provider>
```

Note: `updatePeriodMillis="1800000"` = every 30 minutes.
Android enforces a minimum of 30 minutes for battery reasons.
Real-time updates happen when the Flutter app is open via
`HomeWidget.updateWidget()`.

---

### Step 4 — Create Android widget provider (Kotlin)

Create:
`android/app/src/main/kotlin/com/sakib/amol_tracker_app/AmolWidgetProvider.kt`

```kotlin
package com.sakib.amol_tracker_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

class AmolWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.amol_widget)

            // Read data saved by Flutter
            val score = widgetData.getInt("score", 0)
            val maxScore = widgetData.getInt("maxScore", 100)
            val completedCount = widgetData.getInt("completedCount", 0)
            val totalCount = widgetData.getInt("totalCount", 9)
            val isSubmitted = widgetData.getBoolean("isSubmitted", false)
            val hijriDateDisplay = widgetData.getString(
                "hijriDateDisplay", "আজকের তারিখ"
            ) ?: "আজকের তারিখ"

            // Update views
            views.setTextViewText(R.id.widget_hijri_date, hijriDateDisplay)
            views.setTextViewText(R.id.widget_score, "$score/$maxScore")
            views.setProgressBar(R.id.widget_progress, maxScore, score, false)
            views.setTextViewText(
                R.id.widget_count, "$completedCount/$totalCount আমল"
            )

            // State-based UI
            when {
                isSubmitted -> {
                    views.setTextViewText(
                        R.id.widget_status,
                        "আলহামদুলিল্লাহ — আজকের আমল সম্পন্ন ✓"
                    )
                    views.setTextViewText(R.id.widget_cta, "")
                    views.setInt(
                        R.id.widget_cta,
                        "setVisibility",
                        android.view.View.GONE
                    )
                }
                completedCount > 0 -> {
                    views.setTextViewText(
                        R.id.widget_status,
                        "আমল চলছে... বাকিগুলো সম্পন্ন করো"
                    )
                    views.setTextViewText(R.id.widget_cta, "জমা দাও →")
                    views.setInt(
                        R.id.widget_cta,
                        "setVisibility",
                        android.view.View.VISIBLE
                    )
                }
                else -> {
                    views.setTextViewText(
                        R.id.widget_status,
                        "আজ কোনো আমল লগ হয়নি"
                    )
                    views.setTextViewText(R.id.widget_cta, "আমল লগ করো →")
                    views.setInt(
                        R.id.widget_cta,
                        "setVisibility",
                        android.view.View.VISIBLE
                    )
                }
            }

            // Tap anywhere on widget → open app home screen
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "AMOL_WIDGET_TAP"
                putExtra("route", "/home")
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_cta, pendingIntent)

            // Also make full widget tappable
            views.setOnClickPendingIntent(
                android.R.id.content, pendingIntent
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

---

### Step 5 — Register widget in AndroidManifest.xml

In `android/app/src/main/AndroidManifest.xml`, add inside `<application>`:

```xml
<receiver
    android:name=".AmolWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/amol_widget_info"/>
</receiver>
```

Also add to `android/app/src/main/res/values/strings.xml`:

```xml
<string name="widget_description">আমল ট্র্যাকার — প্রতিদিনের আমলের অগ্রগতি</string>
```

---

### Step 6 — Handle widget tap in MainActivity

In `android/app/src/main/kotlin/com/sakib/amol_tracker_app/MainActivity.kt`:

```kotlin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle widget tap deep link
        HomeWidgetLaunchIntent.getUriFromIntent(intent)?.let { uri ->
            // Flutter will receive this via HomeWidget.initiallyLaunchedFromHomeWidget()
        }
    }
}
```

---

### Step 7 — Integrate HomeWidgetService into Flutter app

#### 7a — Call updateWidget after every amal change

In `lib/providers/amal_provider.dart`, after every state change
(toggle, setNumeric, markAll, submit), call:

```dart
// After state update in AmalNotifier:
_updateHomeWidget(state, ref);

Future<void> _updateHomeWidget(
  Map<String, dynamic> toggles,
  Ref ref,
) async {
  final user = ref.read(currentUserProvider).value;
  final fields = ref.read(amalFieldsProvider).value ?? kDefaultAmalFields;
  final score = calculateScore(toggles, fields);
  final completedCount = _countCompleted(toggles, fields);

  await HomeWidgetService.updateWidget(
    hijriDate: IslamicDateService.getCurrentIslamicDateString(),
    hijriDateDisplay: IslamicDateService.getDisplayIslamicDate(),
    score: score,
    maxScore: kDefaultMaxDa
```
