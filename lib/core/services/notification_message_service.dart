class NotificationContext {
  final int currentStreak;
  final int daysMissed;
  final String userName;
  final bool isEveningCheck;
  final bool isUrgent;

  const NotificationContext({
    required this.currentStreak,
    required this.daysMissed,
    this.userName = '',
    this.isEveningCheck = false,
    this.isUrgent = false,
  });
}

class NotificationMessage {
  final String title;
  final String body;

  const NotificationMessage({required this.title, required this.body});
}

class NotificationMessageService {
  NotificationMessageService._();

  static NotificationMessage getMessage(
    NotificationContext ctx,
    String locale,
  ) {
    if (locale == 'bn') return _getBengaliMessage(ctx);
    return _getEnglishMessage(ctx);
  }

  /// Rotates through [pool] based on current day so the user sees variety.
  static NotificationMessage _pick(List<NotificationMessage> pool) {
    return pool[DateTime.now().day % pool.length];
  }

  // ── Bengali ───────────────────────────────────────────────────────────────

  static NotificationMessage _getBengaliMessage(NotificationContext ctx) {
    // ── SAME DAY — gentle evening reminder ──
    if (ctx.daysMissed == 0 && !ctx.isUrgent) {
      return _pick(const [
        NotificationMessage(
          title: 'আমল লগ করেছেন? 🌙',
          body: 'আজকের আমল এখনো লগ হয়নি। মাত্র কয়েক সেকেন্ড লাগবে।',
        ),
        NotificationMessage(
          title: 'সময় আছে এখনো ⏰',
          body: 'আজকের আমল লগ করুন — ছোট্ট একটা পদক্ষেপ, বড় পুরস্কার।',
        ),
        NotificationMessage(
          title: 'আযকার পড়েছেন? 🤲',
          body: 'দিন শেষ হওয়ার আগে আমল ট্র্যাকারে লগ করুন।',
        ),
        NotificationMessage(
          title: 'আজকের হিসাব কি হলো? 📋',
          body: 'একটু সময় দিন — আজকের আমল লগ করুন।',
        ),
        NotificationMessage(
          title: 'ফজর পড়েছেন? 🌅',
          body: 'দিনের শুরু কেমন হলো — আমল লগ করে দেখুন।',
        ),
      ]);
    }

    // ── SAME DAY — urgent (after 10 PM) ──
    if (ctx.daysMissed == 0 && ctx.isUrgent) {
      if (ctx.currentStreak > 0) {
        return _pick([
          NotificationMessage(
            title: 'আজকের লগটা বাকি আছে 🔥',
            body:
                'তোমার ${ctx.currentStreak} দিনের ধারা চলছে — আজকেরটাও লগ করে রাখো।',
          ),
          NotificationMessage(
            title: '${ctx.currentStreak} দিন দারুণ চলছে! ✨',
            body: 'মাত্র ১০ সেকেন্ড — আজকের আমল লগ করে দাও।',
          ),
          NotificationMessage(
            title: 'রাত হয়ে যাচ্ছে ⏳',
            body:
                '${ctx.currentStreak} দিন ধরে চেষ্টা চালিয়ে যাচ্ছো — চালিয়ে যাও।',
          ),
        ]);
      }
      return _pick(const [
        NotificationMessage(
          title: 'মধ্যরাতের আগে লগ করো ⚡',
          body: 'আজকের আমল লগ করতে ভুলে যাচ্ছ! এখনো সময় আছে।',
        ),
        NotificationMessage(
          title: 'দিন শেষ হতে চলেছে 🌙',
          body: 'আজকের আমলটা লগ করে দিন সম্পূর্ণ করো।',
        ),
      ]);
    }

    // ── MISSED 1 DAY — light, no guilt ──
    if (ctx.daysMissed == 1) {
      if (ctx.currentStreak > 7) {
        return _pick([
          NotificationMessage(
            title: 'কালকে মিস হয়েছে, সমস্যা নেই 😊',
            body:
                '${ctx.currentStreak} দিনের যাত্রাটা দারুণ ছিল — আজ আবার শুরু করো।',
          ),
          NotificationMessage(
            title: 'একটু বিরতি হলো 🙂',
            body:
                '${ctx.currentStreak} দিনের অভিজ্ঞতা তোমার সাথেই আছে। আজ চালিয়ে যাও।',
          ),
          NotificationMessage(
            title: 'কালকে দেখা হয়নি 👋',
            body:
                '${ctx.currentStreak} দিনের ভালো অভ্যাস — আজ আবার শুরু করলেই হয়।',
          ),
        ]);
      }
      return _pick(const [
        NotificationMessage(
          title: 'কালকে আমল হয়নি, ঠিক আছে 🌙',
          body: 'ব্যস্ত ছিলে হয়তো। আজ থেকে আবার শুরু করো।',
        ),
        NotificationMessage(
          title: 'একদিন মিস হয়েছে 😌',
          body: 'কোনো সমস্যা নেই — আজ থেকে আবার এগিয়ে চলো।',
        ),
        NotificationMessage(
          title: 'গতকাল খালি গেছে 📭',
          body: 'আজ একটা আমল দিয়ে শুরু করো।',
        ),
      ]);
    }

    // ── MISSED 2 DAYS — friendly nudge ──
    if (ctx.daysMissed == 2) {
      return _pick(const [
        NotificationMessage(
          title: 'তোমাকে মিস করছি 😊',
          body: '২ দিন হয়ে গেছে — আজ ফিরে আসলে ভালো লাগবে।',
        ),
        NotificationMessage(
          title: 'কিছুদিন বিরতি নিয়েছো 🙂',
          body: 'আজ থেকে আবার শুরু করা যায়, যখনই তুমি প্রস্তুত।',
        ),
        NotificationMessage(
          title: 'তোমার জায়গাটা অপেক্ষায় 🪑',
          body: '২ দিন হয়েছে — আজ একটা ছোট আমল দিয়ে ফিরে আসো।',
        ),
      ]);
    }

    // ── MISSED 3 DAYS — encouraging, no guilt ──
    if (ctx.daysMissed == 3) {
      return _pick(const [
        NotificationMessage(
          title: '৩ দিন হয়ে গেছে 🌱',
          body:
              'যেকোনো সময় আবার শুরু করা যায়। আজ একটা ছোট আমল দিয়ে চেষ্টা করো।',
        ),
        NotificationMessage(
          title: 'নতুন করে শুরু করার সময় ⏳',
          body: 'ছোট একটা আমলও অনেক মূল্যবান। আজ শুরু করো।',
        ),
        NotificationMessage(
          title: 'কয়েকদিন হয়ে গেছে 🤍',
          body: 'কোনো চাপ নেই — আজ যখন সময় হবে, লগ করো।',
        ),
      ]);
    }

    // ── MISSED 4-6 DAYS — warm invitation ──
    if (ctx.daysMissed >= 4 && ctx.daysMissed <= 6) {
      return _pick(const [
        NotificationMessage(
          title: 'আমরা তোমার অপেক্ষায় 🤲',
          body:
              'কয়েকদিন বিরতি হয়েছে — যেকোনো সময় আবার শুরু করা যায়। আজই ফিরে এসো।',
        ),
        NotificationMessage(
          title: 'ফিরে আসার সময় 🧭',
          body:
              'ছোট একটা পদক্ষেপ দিয়েই শুরু হতে পারে আবার। আজ একটা আমল লগ করো।',
        ),
        NotificationMessage(
          title: 'নতুন শুরুর অপেক্ষা 📅',
          body: 'প্রতিটা দিনই নতুন সুযোগ। আজ থেকে আবার শুরু করো।',
        ),
      ]);
    }

    // ── MISSED 7+ DAYS — warm comeback, no guilt ──
    return _pick(const [
      NotificationMessage(
        title: 'অনেকদিন পর... 🌙',
        body:
            'যতদিনই বাদ যাক, আজ থেকে আবার শুরু করা যায় — স্বাগতম ফিরে আসায়।',
      ),
      NotificationMessage(
        title: 'তোমাকে দেখে ভালো লাগবে 🕊️',
        body:
            'যখনই প্রস্তুত, আজ থেকে আবার শুরু করো। একটা ছোট আমল দিয়েই যথেষ্ট।',
      ),
      NotificationMessage(
        title: 'আমরা ভুলে যাইনি তোমায় 💚',
        body:
            'অনেকদিন হয়ে গেল — আজ থেকে আবার শুরু করা যায়, একটা ছোট আমল দিয়ে।',
      ),
    ]);
  }

  // ── English ───────────────────────────────────────────────────────────────

  static NotificationMessage _getEnglishMessage(NotificationContext ctx) {
    // ── SAME DAY — gentle evening reminder ──
    if (ctx.daysMissed == 0 && !ctx.isUrgent) {
      return _pick(const [
        NotificationMessage(
          title: 'Log your amal today 🌙',
          body: "Don't forget your daily habits. It only takes a few seconds.",
        ),
        NotificationMessage(
          title: 'Still time today ⏰',
          body: 'A small step now, a big reward later. Log your amal.',
        ),
        NotificationMessage(
          title: 'Did you read your azkar? 🤲',
          body: 'Log your amal before the day ends.',
        ),
        NotificationMessage(
          title: "How's your day going? 📋",
          body: 'Take a moment to log your amal for today.',
        ),
      ]);
    }

    // ── SAME DAY — urgent (after 10 PM) ──
    if (ctx.daysMissed == 0 && ctx.isUrgent) {
      if (ctx.currentStreak > 0) {
        return _pick([
          NotificationMessage(
            title: "Today's log is still open 🔥",
            body:
                'Your ${ctx.currentStreak}-day streak is going strong — log today\'s amal too.',
          ),
          NotificationMessage(
            title: '${ctx.currentStreak} days going great! ✨',
            body: 'Just 10 seconds — log your amal for today.',
          ),
          NotificationMessage(
            title: 'Getting late ⏳',
            body:
                "You've kept it up for ${ctx.currentStreak} days. Keep going!",
          ),
        ]);
      }
      return _pick(const [
        NotificationMessage(
          title: 'Last chance tonight ⚡',
          body: 'Log your amal before midnight. You still have time!',
        ),
        NotificationMessage(
          title: 'The day is ending! 🌙',
          body: 'Log your amal to round off the day.',
        ),
      ]);
    }

    // ── MISSED 1 DAY — light, no guilt ──
    if (ctx.daysMissed == 1) {
      if (ctx.currentStreak > 7) {
        return _pick([
          NotificationMessage(
            title: 'Missed yesterday, no worries 😊',
            body:
                'Your ${ctx.currentStreak}-day journey was great — pick it back up today.',
          ),
          NotificationMessage(
            title: 'Just a short pause 🙂',
            body:
                '${ctx.currentStreak} days of progress is still with you. Continue today.',
          ),
          NotificationMessage(
            title: "Didn't see you yesterday 👋",
            body:
                '${ctx.currentStreak} days of good habit — just pick it up again today.',
          ),
        ]);
      }
      return _pick(const [
        NotificationMessage(
          title: 'Missed yesterday, that\'s okay 🌙',
          body: 'Maybe you were busy. Start again today.',
        ),
        NotificationMessage(
          title: 'One day missed 😌',
          body: 'No worries — today is a fresh chance to continue.',
        ),
        NotificationMessage(
          title: 'Yesterday was quiet 📭',
          body: 'Start today with one small amal.',
        ),
      ]);
    }

    // ── MISSED 2 DAYS — friendly nudge ──
    if (ctx.daysMissed == 2) {
      return _pick(const [
        NotificationMessage(
          title: 'Missing you here 😊',
          body: "It's been 2 days — it'd be great to see you back today.",
        ),
        NotificationMessage(
          title: 'Taking a short break 🙂',
          body: 'Whenever you\'re ready, today is a good day to start again.',
        ),
        NotificationMessage(
          title: 'Your spot is waiting 🪑',
          body: '2 days so far — come back today with one small amal.',
        ),
      ]);
    }

    // ── MISSED 3 DAYS — encouraging, no guilt ──
    if (ctx.daysMissed == 3) {
      return _pick(const [
        NotificationMessage(
          title: '3 days so far 🌱',
          body: 'You can always start again. Try one small amal today.',
        ),
        NotificationMessage(
          title: 'A good time for a fresh start ⏳',
          body: 'Even a small amal counts. Start today.',
        ),
        NotificationMessage(
          title: 'A few days have passed 🤍',
          body: 'No pressure — log whenever it works for you today.',
        ),
      ]);
    }

    // ── MISSED 4-6 DAYS — warm invitation ──
    if (ctx.daysMissed >= 4 && ctx.daysMissed <= 6) {
      return _pick(const [
        NotificationMessage(
          title: "We're here whenever you're ready 🤲",
          body:
              "It's been a few days — you can pick up again anytime. Come back today.",
        ),
        NotificationMessage(
          title: 'A good moment to return 🧭',
          body: 'One small step is all it takes to restart. Log an amal today.',
        ),
        NotificationMessage(
          title: 'A fresh start awaits 📅',
          body: 'Every day is a new opportunity. Start again today.',
        ),
      ]);
    }

    // ── MISSED 7+ DAYS — warm comeback, no guilt ──
    return _pick(const [
      NotificationMessage(
        title: 'Long time no see 🌙',
        body:
            'No matter how long it\'s been, today is a great day to start again. Welcome back.',
      ),
      NotificationMessage(
        title: 'It\'ll be great to see you 🕊️',
        body:
            'Whenever you\'re ready, start again today. One small amal is all it takes.',
      ),
      NotificationMessage(
        title: "We didn't forget you 💚",
        body:
            "It's been a while — but today you can start again, one small amal at a time.",
      ),
    ]);
  }
}
