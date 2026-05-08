# Cursor Prompt: Update Notification Text & Times Only

## Context

This is a Flutter app (`notification_service.dart`) for Bangladeshi Muslim users tracking daily Islamic habits (amal). We need to update **only the notification titles, body text, and scheduled times** for 6 existing notifications.

**Do NOT change:**

- Any notification logic, scheduling mechanism, or trigger conditions
- Quiet hours logic — but update the default values (see below)
- User customization settings (which notifications are customizable stays the same)
- Tap routes
- Pre-scheduling behavior (e.g. hadith notifications pre-scheduled for next 7 days)
- Any function signatures, method names, or class structure
- Anything outside of `notification_service.dart`

---

## Changes Required

### Quiet Hours Default Values Only

**Chosen safe window: `quietFrom = 22:30`, `quietTo = 05:00`**

This was derived by mapping every notification time and ensuring none falls inside the suppressed range:

| Notification     | New Time    | Falls in quiet 22:30→05:00? |
| ---------------- | ----------- | --------------------------- |
| Morning reminder | 6:30 AM     | ✅ Safe (after 05:00)       |
| Evening reminder | 5:00 PM     | ✅ Safe (before 22:30)      |
| Streak warning   | 10:15 PM    | ✅ Safe (before 22:30)      |
| Jumuah reminder  | Fri 9:30 AM | ✅ Safe (after 05:00)       |
| Hadith morning   | 8:00 AM     | ✅ Safe (after 05:00)       |
| Hadith evening   | 9:00 PM     | ✅ Safe (before 22:30)      |

**Why not earlier quiet start (e.g. 22:00)?** The streak warning at 10:15 PM would be suppressed — same bug as before. 22:30 is the tightest safe cutoff that lets 10:15 PM through.

**Why not later quiet end (e.g. 06:00)?** The morning reminder at 6:30 AM would still be safe at 06:00, but 05:00 gives a clean buffer before Fajr (~5:10 AM Dhaka summer) in case a user sets their morning reminder to an earlier custom time like 5:30 AM.

Update the default quiet hours constants/values:

- `quietFrom` → `22:30` (hour: 22, min: 30) — was `21:00`
- `quietTo` → `05:00` (hour: 5, min: 0) — was `06:00`

---

### Notification 1 — Morning Reminder

| Field        | Old Value                        | New Value                                                 |
| ------------ | -------------------------------- | --------------------------------------------------------- |
| Default time | `6:00 AM` (hour: 6, min: 0)      | `6:30 AM` (hour: 6, min: 30)                              |
| Title        | `সকালের নোটিফিকেশন`              | `ফজরের পর — আমলের শুরু`                                   |
| Body         | `আজকের আমল দিয়ে দিন শুরু করুন।` | `সকালের আযকার পড়েছেন? দিনের প্রথম আমলটি এখনই শুরু করুন।` |

---

### Notification 2 — Evening Reminder

| Field        | Old Value                                        | New Value                                                             |
| ------------ | ------------------------------------------------ | --------------------------------------------------------------------- |
| Default time | `6:30 PM` (hour: 18, min: 30)                    | `5:00 PM` (hour: 17, min: 0)                                          |
| Title        | `সন্ধ্যার নোটিফিকেশন`                            | `আসরের পর — সন্ধ্যার প্রস্তুতি`                                       |
| Body         | `সন্ধ্যার আযকার ও কুরআন তিলাওয়াত মিস করবেন না।` | `সন্ধ্যার আযকারের সময় হয়ে আসছে। মাগরিবের আগেই আমলনামা সাজিয়ে নিন।` |

---

### Notification 3 — Streak Warning

| Field        | Old Value                                                    | New Value                                                                                                  |
| ------------ | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| Default time | `10:00 PM` (hour: 22, min: 0)                                | `10:15 PM` (hour: 22, min: 15)                                                                             |
| Title        | `স্ট্রিক সতর্কতা`                                            | `আজকের আমল বাকি আছে!`                                                                                      |
| Body         | `আজকের লগ এখনো না দিলে এখনই সাবমিট করুন, স্ট্রিক ধরে রাখুন।` | `রাত শেষ হওয়ার আগেই লগ দিন — একটি দিন মিস করলে স্ট্রিক শেষ। আল্লাহ ছোট হলেও নিয়মিত আমল বেশি পছন্দ করেন।` |

---

### Notification 4 — Jumuah Weekly Reminder

| Field        | Old Value                          | New Value                                                                              |
| ------------ | ---------------------------------- | -------------------------------------------------------------------------------------- |
| Default time | `Friday 8:00 AM` (hour: 8, min: 0) | `Friday 9:30 AM` (hour: 9, min: 30)                                                    |
| Title        | `জুমআর অনুপ্রেরণা`                 | `জুমআর দিন — সেরা আমলের দিন`                                                           |
| Body         | `মুবারক জুমআ। আজ আমলে দৃঢ় থাকুন।` | `জুমআর দিনে সূরা কাহফ তিলাওয়াত করুন, দরূদ বেশি বেশি পড়ুন। আজকের আমলনামা পূর্ণ করুন।` |

---

### Notification 5 — Hadith Morning

| Field                                            | Old Value                   | New Value                                      |
| ------------------------------------------------ | --------------------------- | ---------------------------------------------- |
| Default time                                     | `7:00 AM` (hour: 7, min: 0) | `8:00 AM` (hour: 8, min: 0)                    |
| Title                                            | `আজকের হাদীস (সকাল)`        | `আজকের হাদীস ☀️`                               |
| Body suffix (appended after dynamic hadith text) | _(none / just the hadith)_  | `— সকালের অনুপ্রেরণা নিন এবং আমলে লেগে থাকুন।` |

> **Note:** If the body is purely dynamic hadith text with no suffix, add the suffix as a separate line or appended string — whichever pattern already exists in the code. Do not restructure how the hadith text is fetched or inserted.

---

### Notification 6 — Hadith Evening

| Field                                            | Old Value                    | New Value                                  |
| ------------------------------------------------ | ---------------------------- | ------------------------------------------ |
| Default time                                     | `8:00 PM` (hour: 20, min: 0) | `9:00 PM` (hour: 21, min: 0)               |
| Title                                            | `আজকের হাদীস (রাত)`          | `রাতের হাদীস 🌙`                           |
| Body suffix (appended after dynamic hadith text) | _(none / just the hadith)_   | `— ঘুমানোর আগে হাদীসের কথা মনে নিয়ে শুন।` |

---

## Important Constraints

1. **String literals only** — only change the string values listed above. If titles/bodies are stored as constants, keys, or in a separate strings/localization file, update them there instead and leave `notification_service.dart` referencing the same keys.
2. **Time values** — update only the default hour/minute integers used when the user has not customized the time. Do not touch the Hive key names or the read logic that loads user-overridden times.
3. **No reformat, no reorder** — do not reformat the file, reorder methods, or change indentation of surrounding code.
4. **One file scope** — all changes must be contained to whichever file(s) hold the string literals and default time values for these notifications. Do not touch any other file.
5. **Verify build compiles** — after changes, confirm there are no syntax errors. Bengali Unicode strings are valid Dart string literals.
