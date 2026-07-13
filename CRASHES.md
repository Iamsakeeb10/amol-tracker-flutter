# Firebase Crashlytics Audit Report

> **Project:** Amol Tracker
>
> **Purpose:** Independent AI audit of the Crashlytics reports.
>
> **Methodology:** The following findings are derived from the provided Crashlytics stack traces. Each issue includes the original crash information followed by an AI-based root cause analysis and possible fixes. The suggested fixes should be validated against the actual implementation before being applied.

---

# Crash 1

## Original Crash

```
GoException: Exception during redirect:
[cloud_firestore/unavailable]
The service is currently unavailable.
```

---

## AI Audit

### Observed Stack

```
GoRouter.redirect()
↓
FirebaseFirestore.documentReferenceGet()
↓
FirebaseException (cloud_firestore/unavailable)
↓
GoException
```

### Possible Root Cause

The routing logic appears to perform a Firestore request while resolving a redirect.

During navigation, Firestore may temporarily become unavailable due to:

- Device offline
- Poor network connectivity
- Temporary Firestore backend issue
- Startup race conditions

The exception appears to propagate through the redirect callback without being gracefully handled, resulting in a fatal navigation failure.

### Potential Improvements

- Audit every Firestore call executed inside GoRouter redirect callbacks.
- Consider avoiding network requests during routing.
- Catch transient Firebase exceptions (`unavailable`, `deadline-exceeded`, etc.).
- Prefer cached or locally available authentication/session state for redirect decisions.
- Retry transient failures instead of allowing the exception to terminate navigation.

---

# Crash 2

## Original Crash

```
Exception

Failed to load font with url

https://fonts.gstatic.com/...
```

---

## AI Audit

### Observed Stack

```
google_fonts
↓
Runtime font download
↓
Network failure
↓
Exception
```

### Possible Root Cause

The application appears to request Google Fonts dynamically at runtime.

Runtime font downloads can fail because of:

- No internet connection
- DNS failure
- Slow network
- Request timeout
- Network restrictions

If the application depends on a successful download without fallback handling, a fatal exception may occur.

### Potential Improvements

- Audit whether runtime font fetching is enabled.
- Bundle required fonts within the application package.
- Disable runtime fetching if remote fonts are not required.
- Provide graceful fallback fonts when remote resources cannot be loaded.

---

# Crash 3

## Original Crash

```
Failed assertion:

ref.listen can only be used
within the build method
of a ConsumerWidget
```

---

## AI Audit

### Observed Stack

```
_AmolTrackerAppState.initState()
↓
_setupCrashlytics()
↓
ref.listen(...)
↓
Assertion Failure
```

### Possible Root Cause

The stack trace suggests that a Riverpod listener may be registered from a lifecycle method that does not permit `ref.listen()`.

Riverpod enforces lifecycle restrictions to avoid invalid listener registrations.

### Potential Improvements

- Audit all usages of `ref.listen()`.
- Verify that listeners are only registered in supported lifecycle locations.
- Evaluate whether `ref.read()` or `ref.listenManual()` is more appropriate for the current implementation.
- Review global initialization logic executed during application startup.

---

# Crash 4

## Original Crash

```
PlatformException

Attempt to invoke

Context.checkPermission()

on a null object reference
```

---

## AI Audit

### Observed Stack

```
NotificationService.initialize()
↓
_ensureLocalNotificationPermission()
↓
requestNotificationsPermission()
↓
Null Context
```

### Possible Root Cause

The notification permission request appears to occur before Android has attached a valid Activity or Context.

This may happen during early application initialization or while the application lifecycle has not yet reached a state where notification APIs are available.

### Potential Improvements

- Audit notification initialization timing.
- Delay permission requests until the application is fully attached.
- Verify Activity availability before requesting permissions.
- Ensure plugin initialization follows Flutter and Android lifecycle recommendations.

---

# Crash 5

## Original Crash

```
Fatal Exception:

[cloud_firestore/unavailable]

The service is currently unavailable.

This is most likely a transient condition and may be corrected by retrying with a backoff.
```

### Observed Stack

```
NotificationService._hasLoggedIslamicDate()
↓
NotificationService._cancelUrgencyIfLoggedToday()
↓
NotificationService.scheduleAll()
↓
NotificationService.rescheduleAll()
↓
_AmolTrackerAppState._onAppResumed()
```

---

## AI Audit

### Possible Root Cause

The application appears to perform a Firestore document read while rescheduling notifications after the application resumes.

Since this operation depends on network availability, temporary Firestore outages or offline conditions may result in an uncaught exception.

Because the failure occurs during an application lifecycle callback, the exception propagates to Crashlytics as a fatal error.

### Potential Improvements

- Audit Firestore calls executed during application resume.
- Handle transient Firestore exceptions (`unavailable`) gracefully.
- Consider using locally cached data when determining notification schedules.
- Retry transient failures using an exponential backoff strategy.
- Avoid making notification scheduling dependent on immediate network availability.

---

# Overall AI Assessment

Based on the provided Crashlytics reports, the crashes appear to fall into the following categories:

| Category                             | Count |
| ------------------------------------ | ----: |
| Firestore transient/network handling |     2 |
| Application lifecycle timing         |     2 |
| Riverpod lifecycle misuse            |     1 |
| Runtime resource loading             |     1 |

## General Recommendations

The audit suggests reviewing the following areas across the application:

- Exception handling for all Firebase and Firestore operations.
- Startup and application lifecycle logic.
- Riverpod listener registration patterns.
- Notification initialization sequence.
- Network-dependent operations executed during startup or resume.
- Runtime resource loading (fonts and other remote assets).
- Offline behavior and graceful degradation strategies.
- Retry mechanisms for transient backend failures.
- Centralized logging and defensive error handling for lifecycle callbacks.

---

# Disclaimer

This report is an AI-assisted audit based solely on the supplied Crashlytics stack traces. The suggested causes and improvements represent the most probable implementation issues inferred from the stack traces and should be verified against the application's source code before changes are made.
