How Duolingo Does It
Duolingo uses a combination of 3 systems working together:

1. Local Notifications (Scheduled on device)
   For time-based reminders like "You haven't practiced today." These are scheduled directly on the device using the local notification system — no internet needed. They fire at a specific time every day.
2. Firebase Cloud Messaging (FCM Push)
   For server-triggered notifications like "Your friend just beat your score." These come from Duolingo's backend when a specific event happens.
3. Smart Timing Algorithm
   Duolingo tracks what time you usually practice. If you practice at 8 PM every day, it sends the reminder at 7:30 PM — just before your usual time. If you haven't practiced by 10 PM it sends the urgent one.

Their Famous Emotional Messages
Duolingo rotates through different emotional tones based on how many days you've missed:
Days missedToneExampleSame day (evening)Gentle"Don't forget to practice today!"1 day missedSad"You missed yesterday. Duo is heartbroken 💔"2 days missedGuilt"Duo hasn't slept. He's been waiting for you 😢"3+ days missedPassive aggressive"Oh hi. Didn't see you yesterday. Or the day before."Streak about to breakUrgent"Your X day streak ends tonight! 🔥"
The emotional escalation is the key. Same message every day = ignored. Escalating emotion = user feels it.

How to Build This for Amol Tracker
The Architecture
Flutter App
│
├── On every app open → check last log date
│ └── Schedule/reschedule local notifications
│ based on current streak + days missed
│
├── Firebase Cloud Functions
│ └── Run daily at 9 PM Bangladesh time
│ → Find users who haven't logged today
│ → Send FCM push to those users
│ → Message varies based on streak + days missed
│
└── Local notification scheduler
└── Scheduled at user's preferred time
→ Escalates message based on days missed

Implementation Prompt for Cursor
Implement an emotional escalating notification system
for Amol Tracker similar to Duolingo's reminder system.

---

BEFORE WRITING ANY CODE read these files:

- lib/core/services/notification_service.dart
- lib/core/services/islamic_date_service.dart
- lib/core/services/firestore_service.dart
- lib/providers/auth_provider.dart
- lib/providers/amal_provider.dart
- pubspec.yaml

---

## WHAT TO BUILD

A smart notification system that:

1. Sends emotionally varied messages based on how
   many days the user has missed
2. Escalates urgency as more days are missed
3. References the user's streak to create loss aversion
4. Uses Islamic language and tone — never rude,
   always caring like a brother reminding another
5. Fires at the right time — not too early, not too late

---

## STEP 1 — Create NotificationMessageService

Create: lib/core/services/notification_message_service.dart

This service returns the right message based on context.

class NotificationContext {
final int currentStreak; // user's current streak
final int daysMissed; // how many days since last log
final String userName; // user's display name
final bool isEveningCheck; // true = evening reminder
final bool isUrgent; // true = after 10 PM
}

class NotificationMessage {
final String title;
final String body;
}

class NotificationMessageService {

static NotificationMessage getMessage(
NotificationContext ctx,
String locale, // 'bn' or 'en'
) {
if (locale == 'bn') {
return \_getBengaliMessage(ctx);
}
return \_getEnglishMessage(ctx);
}

static NotificationMessage \_getBengaliMessage(
NotificationContext ctx,
) {
// SAME DAY — not logged yet, gentle reminder
if (ctx.daysMissed == 0 && !ctx.isUrgent) {
final messages = [
NotificationMessage(
title: 'আমল লগ করেছেন? 🌙',
body: 'আজকের আমল এখনো লগ হয়নি। '
'মাত্র কয়েক সেকেন্ড লাগবে।',
),
NotificationMessage(
title: 'সময় আছে এখনো ⏰',
body: 'আজকের আমল লগ করুন — '
'ছোট্ট একটা পদক্ষেপ, বড় পুরস্কার।',
),
NotificationMessage(
title: 'আযকার পড়েছেন? 🤲',
body: 'দিন শেষ হওয়ার আগে আমল '
'ট্র্যাকারে লগ করুন।',
),
];
return messages[
DateTime.now().day % messages.length
];
}

    // SAME DAY — urgent (after 10 PM)
    if (ctx.daysMissed == 0 && ctx.isUrgent) {
      if (ctx.currentStreak > 0) {
        return NotificationMessage(
          title: 'স্ট্রিক শেষ হয়ে যাবে! 🔥',
          body: 'তোমার ${ctx.currentStreak} দিনের '
              'স্ট্রিক আজ রাতেই শেষ হবে। '
              'এখনই লগ করো!',
        );
      }
      return NotificationMessage(
        title: 'মধ্যরাতের আগে লগ করো ⚡',
        body: 'আজকের আমল লগ করতে ভুলে '
            'যাচ্ছ! এখনো সময় আছে।',
      );
    }

    // MISSED 1 DAY — sad/concerned tone
    if (ctx.daysMissed == 1) {
      if (ctx.currentStreak > 7) {
        return NotificationMessage(
          title: 'গতকাল মিস হয়েছে 😔',
          body: '${ctx.currentStreak} দিনের পরিশ্রম '
              'ছেড়ে দেবে? আজ ফিরে এসো।',
        );
      }
      return NotificationMessage(
        title: 'গতকাল আমল হয়নি 🌙',
        body: 'কাল ব্যস্ত ছিলে হয়তো। '
            'আজ থেকে আবার শুরু করো ইনশাআল্লাহ।',
      );
    }

    // MISSED 2 DAYS — worried tone
    if (ctx.daysMissed == 2) {
      return NotificationMessage(
        title: '২ দিন ধরে দেখছি না 😢',
        body: 'তুমি ছাড়া কমিউনিটি অসম্পূর্ণ। '
            'আজ ফিরে এসো।',
      );
    }

    // MISSED 3 DAYS — gentle guilt
    if (ctx.daysMissed == 3) {
      return NotificationMessage(
        title: '৩ দিন হয়ে গেল... 💔',
        body: '"যে আমল নিয়মিত করা হয়, '
            'সেটাই আল্লাহর কাছে সবচেয়ে প্রিয়।" '
            'আজ ফিরে আসো।',
      );
    }

    // MISSED 4-6 DAYS — hadith motivation
    if (ctx.daysMissed >= 4 && ctx.daysMissed <= 6) {
      return NotificationMessage(
        title: 'আমরা তোমার অপেক্ষায় 🤲',
        body: 'কয়েকদিন মিস হয়েছে — '
            'কিন্তু তওবা করার দরজা সবসময় খোলা। '
            'আজই ফিরে এসো।',
      );
    }

    // MISSED 7+ DAYS — compassionate comeback
    return NotificationMessage(
      title: 'অনেকদিন পর... 🌙',
      body: 'যতদিনই বাদ যাক, আজ থেকে '
          'নতুন করে শুরু করা যায়। '
          'আল্লাহ তওবা ভালোবাসেন।',
    );

}

static NotificationMessage \_getEnglishMessage(
NotificationContext ctx,
) {
if (ctx.daysMissed == 0 && !ctx.isUrgent) {
return NotificationMessage(
title: 'Log your amal today 🌙',
body: 'Don\'t forget your daily habits. '
'It only takes a few seconds.',
);
}

    if (ctx.daysMissed == 0 && ctx.isUrgent) {
      if (ctx.currentStreak > 0) {
        return NotificationMessage(
          title: 'Your ${ctx.currentStreak}-day streak ends tonight! 🔥',
          body: 'Log your amal before midnight '
              'to keep your streak alive.',
        );
      }
      return NotificationMessage(
        title: 'Last chance tonight ⚡',
        body: 'Log your amal before midnight. '
            'You still have time!',
      );
    }

    if (ctx.daysMissed == 1) {
      return NotificationMessage(
        title: 'You missed yesterday 😔',
        body: 'Come back today and keep going. '
            'Every day is a fresh start.',
      );
    }

    if (ctx.daysMissed == 2) {
      return NotificationMessage(
        title: '2 days without amal 😢',
        body: 'The community misses you. '
            'Come back today.',
      );
    }

    if (ctx.daysMissed == 3) {
      return NotificationMessage(
        title: '3 days... 💔',
        body: '"The most beloved deeds are those '
            'done consistently." Come back today.',
      );
    }

    if (ctx.daysMissed >= 4 && ctx.daysMissed <= 6) {
      return NotificationMessage(
        title: 'We\'re waiting for you 🤲',
        body: 'It\'s not too late. '
            'Start fresh today, inshallah.',
      );
    }

    return NotificationMessage(
      title: 'Long time no see 🌙',
      body: 'No matter how long, today is a '
          'new beginning. Allah loves those '
          'who return to Him.',
    );

}
}

---

## STEP 2 — Update NotificationService

In lib/core/services/notification_service.dart:

Replace the existing basic reminder scheduling with
this smart system:

/// Call this on every app open and after every
/// amal submission
Future<void> scheduleSmartReminders({
required String uid,
required int currentStreak,
required String? lastLogDate,
required String locale,
}) async {
// Cancel all existing scheduled notifications
await \_cancelAllReminders();

final today = IslamicDateService
.getCurrentIslamicDateString();
final hasLoggedToday = lastLogDate == today;

// Calculate days missed
int daysMissed = 0;
if (lastLogDate != null && lastLogDate != today) {
daysMissed = IslamicDateService
.daysBetween(lastLogDate, today);
}

if (hasLoggedToday) {
// Already logged — no reminders needed today
// Schedule tomorrow's morning reminder
await \_scheduleMorningReminder(
daysMissed: 0,
streak: currentStreak,
locale: locale,
);
return;
}

// Schedule evening reminder (user's set time or 6:30 PM)
final eveningMessage = NotificationMessageService
.getMessage(
NotificationContext(
currentStreak: currentStreak,
daysMissed: daysMissed,
isEveningCheck: true,
isUrgent: false,
),
locale,
);
await \_scheduleAt(
id: 1,
hour: 18,
minute: 30,
title: eveningMessage.title,
body: eveningMessage.body,
);

// Schedule urgent reminder at 10 PM
final urgentMessage = NotificationMessageService
.getMessage(
NotificationContext(
currentStreak: currentStreak,
daysMissed: daysMissed,
isEveningCheck: false,
isUrgent: true,
),
locale,
);
await \_scheduleAt(
id: 2,
hour: 22,
minute: 0,
title: urgentMessage.title,
body: urgentMessage.body,
);
}

---

## STEP 3 — Add daysBetween to IslamicDateService

In lib/core/services/islamic_date_service.dart add:

static int daysBetween(
String fromHijriDate,
String toHijriDate,
) {
try {
final from = _parseHijriToGregorian(fromHijriDate);
final to = \_parseHijriToGregorian(toHijriDate);
return to.difference(from).inDays;
} catch (_) {
return 0;
}
}

---

## STEP 4 — Call scheduleSmartReminders at the right times

Call this method in these 4 places:

1. App startup (main.dart or app.dart) — after user loads
2. After successful amal submission
3. After Maghrib (Islamic date changes)
4. When app comes to foreground (AppLifecycleState.resumed)

Example:
ref.listen(currentUserProvider, (prev, next) {
final user = next.value;
if (user == null) return;
notificationService.scheduleSmartReminders(
uid: user.uid,
currentStreak: user.currentStreak,
lastLogDate: user.lastLogDate,
locale: ref.read(localeProvider).languageCode,
);
});

---

## STEP 5 — FCM Cloud Function (server-side push)

Create functions/sendDailyReminders.js:

This runs every day at 9:00 PM Bangladesh time and
sends push notifications to users who haven't logged.

const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendDailyReminders = functions.pubsub
.schedule('0 15 \* \* \*') // 9 PM Bangladesh = 3 PM UTC
.timeZone('Asia/Dhaka')
.onRun(async (context) => {
const db = admin.firestore();
const today = getIslamicDateString(); // implement this

    // Get all users who haven't logged today
    const usersSnap = await db.collection('users')
      .where('lastLogDate', '!=', today)
      .where('fcmToken', '!=', null)
      .get();

    const batch = [];
    usersSnap.docs.forEach(doc => {
      const user = doc.data();
      const daysMissed = getDaysMissed(
        user.lastLogDate, today
      );

      // Only send if user has FCM token and
      // notifications enabled
      if (!user.fcmToken) return;

      const message = getMessageForUser(
        user.currentStreak,
        daysMissed,
        user.locale ?? 'bn',
      );

      batch.push(
        admin.messaging().send({
          token: user.fcmToken,
          notification: {
            title: message.title,
            body: message.body,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'amal_reminders',
              sound: 'default',
            },
          },
          data: {
            route: '/home',
            type: 'daily_reminder',
          },
        })
      );
    });

    await Promise.allSettled(batch);
    console.log(
      `Sent reminders to ${batch.length} users`
    );

});

---

## WHAT NOT TO DO

- Do NOT send more than 2 notifications per day
- Do NOT send notifications during quiet hours
- Do NOT send if user has notifications disabled
- Do NOT use scary or threatening language
- Do NOT guilt-trip excessively — Islamic tone always
- Do NOT send if user already logged today

---

## TESTING CHECKLIST

- [ ] Log amal today → no evening reminder fires
- [ ] Don't log → evening reminder fires at 6:30 PM
- [ ] Don't log → urgent reminder fires at 10 PM
      with streak warning if streak > 0
- [ ] Miss 1 day → message mentions missing yesterday
- [ ] Miss 3 days → hadith quote appears in message
- [ ] Miss 7+ days → compassionate comeback message
- [ ] Bengali locale → Bengali message
- [ ] English locale → English message
- [ ] Quiet hours set → no notification during window
- [ ] Notification tapped → opens home screen

---

## IMPLEMENTATION ORDER

1. NotificationMessageService — all messages
2. IslamicDateService.daysBetween()
3. Update NotificationService.scheduleSmartReminders()
4. Call it from 4 trigger points
5. Deploy Cloud Function for server-side FCM
6. Test each message tone manually

The Key Insight from Duolingo
The reason their notifications work is loss aversion — people fear losing something more than they want to gain something.
For Amol Tracker the equivalent is:

Streak loss — "Your 12-day streak ends tonight" is more powerful than "Log your amal today"
Community comparison — "Everyone else has logged today" triggers social pressure
Islamic guilt done gently — quoting a hadith is more moving than a generic reminder
Escalation — same message every day = ignored. Different message each day = noticed

These four together will make your notification system feel alive and personal — exactly like Duolingo's owl. 🦉
