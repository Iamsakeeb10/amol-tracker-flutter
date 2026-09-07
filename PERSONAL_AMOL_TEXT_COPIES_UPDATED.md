# Personal Amol — Rewritten Copy (Human / BD-app style)

> Goal: sound like bKash, Nagad, or a BD newspaper app — short, direct, everyday words.
> Not: textbook Bangla, literal English translation, or "please enter" style politeness.
>
> Rule of thumb used throughout:
> - **এডিট / ডিলিট / সেভ** — used instead of সম্পাদনা / মুছে ফেলুন / সংরক্ষণ, because that's what people actually say.
> - **বাতিল করুন** — used instead of ক্যানসেল, because it's just as natural and fully Bangla.
> - Sentences are shortened. "অনুগ্রহ করে" (please) dropped — BD apps don't beg, they just tell you what to do.
> - English side is also tightened — dropped redundant words ("Personal Amol" → "New Amol" inside a sheet that's already under the Personal Amol section).

---

## 1. Section Header

| Key | English | Bangla |
|---|---|---|
| `personalAmolSectionTitle` | My Amol | আমার আমল |

*Note: changed from "Personal Amol" → "My Amol" / "আমার আমল" — more personal, same feel as "আমার bKash". This title is reused in a few places below (list screen, history section) — I kept it consistent everywhere.*

---

## 2. Empty State

| Key | English | Bangla |
|---|---|---|
| `personalAmolEmptyHeadline` | Add your first amol | আপনার প্রথম আমল যোগ করুন |
| `personalAmolEmptySubtitle` | Any daily habit — just for you | যেকোনো দৈনন্দিন অভ্যাস, শুধু আপনার জন্য |
| `personalAmolEmptyCta` | Add | যোগ করুন |

---

## 3. "None Due Today"

| Key | English | Bangla |
|---|---|---|
| `personalAmolNoneDueToday` | No amol for today | আজ কোনো আমল নেই |

---

## 4. List Screen

| Key | English | Bangla |
|---|---|---|
| `personalAmolListTitle` | My Amol | আমার আমল |

---

## 5. Cap / Limit Warning

| Key | English | Bangla |
|---|---|---|
| `personalAmolCapMessage` | You've reached the {max} amol limit | আপনি {max}টি আমলের সীমায় পৌঁছে গেছেন |

---

## 6. Create / Edit Sheet

### Sheet Titles
| Key | English | Bangla |
|---|---|---|
| `personalAmolCreateTitle` | New Amol | নতুন আমল |
| `personalAmolEditTitle` | Edit Amol | আমল এডিট করুন |

### Name Field
| Key | English | Bangla |
|---|---|---|
| `personalAmolNameLabel` | Name | নাম |
| `personalAmolNameHint` | e.g. Reading Quran, Daily Dua | যেমনঃ কুরআন পড়া, দোয়া পড়া |
| `personalAmolNameRequired` | Enter a name | একটি নাম দিন |

### Icon Picker
| Key | English | Bangla |
|---|---|---|
| `personalAmolIconLabel` | Icon | আইকন |
| `personalAmolSeeAllIcons` | See all | সব দেখুন |
| `personalAmolIconPickerTitle` | Pick an icon | আইকন বাছাই করুন |

### Tracking Type
| Key | English | Bangla |
|---|---|---|
| `personalAmolTypeLabel` | Tracking type | ট্র্যাকিংয়ের ধরন |
| `personalAmolTypeToggle` | Done / Not done | হ্যাঁ / না |
| `personalAmolTypeCount` | Count | গণনা |

### Daily Target
| Key | English | Bangla |
|---|---|---|
| `personalAmolTargetLabel` | Daily target | দৈনিক লক্ষ্য |
| `personalAmolTargetHint` | Times per day | দিনে কতবার |

### Frequency
| Key | English | Bangla |
|---|---|---|
| `personalAmolFrequencyLabel` | Repeat | কবে করবেন |
| `personalAmolFrequencyDaily` | Every day | প্রতিদিন |
| `personalAmolFrequencyWeekdays` | Choose days | নির্দিষ্ট দিনে |

### Weekday Chips
No change — these already render as শনি, রবি, সোম, মঙ্গল, বুধ, বৃহস্পতি, শুক্র in both locales. That part is fine as-is.

### Sheet Actions
| Key | English | Bangla |
|---|---|---|
| `personalAmolAddLabel` | Add | যোগ করুন |
| `personalAmolSaveLabel` | Save | সেভ করুন |

---

## 7. Tile / Card

| Key | English | Bangla |
|---|---|---|
| `personalAmolFrequencyDaily` | Every day | প্রতিদিন |
| `personalAmolFrequencyWeekdays` | Choose days | নির্দিষ্ট দিনে |
| `dayStreak` | {days}-day streak | {days} দিনের স্ট্রিক |
| `personalAmolCountMaxReached` | Target reached! | লক্ষ্য পূরণ হয়ে গেছে! |
| `personalAmolCountMinReached` | Already at 0 | গণনা এখন ০, আর কমানো যাবে না |

---

## 8. Delete Flow

| Key | English | Bangla |
|---|---|---|
| `personalAmolDeleteConfirm` | Delete this amol? | এই আমলটি ডিলিট করবেন? |
| `personalAmolDeleteSubtitle` | Your history won't be deleted | শুধু আমলটি ডিলিট হবে, আপনার হিস্টোরি থাকবে |
| `personalAmolDeleteLabel` | Delete | ডিলিট করুন |
| `personalAmolEditLabel` | Edit | এডিট করুন |
| `delete` *(shared)* | Delete | ডিলিট করুন |
| `cancel` *(shared)* | Cancel | বাতিল করুন |

*Fixed: `delete` and `personalAmolDeleteLabel` now both say ডিলিট করুন — no more mismatch in the same dialog.*

---

## 9. Details Dialog

| Key | English | Bangla |
|---|---|---|
| `personalAmolProgressLabel` | {done}/{total} completed | {done}/{total} সম্পন্ন |
| `personalAmolTypeToggle` | Done / Not done | হ্যাঁ / না |
| `personalAmolTypeCount` | Count | গণনা |
| `personalAmolTargetLabel` | Daily target | দৈনিক লক্ষ্য |
| `dayStreak` | {days}-day streak | {days} দিনের স্ট্রিক |
| `historyBestStreak` *(shared)* | Best streak | সেরা স্ট্রিক |
| `personalAmolEditLabel` | Edit | এডিট করুন |
| `cancel` *(shared)* | Cancel | বাতিল করুন |

---

## 10. History / Day Detail

| Key | English | Bangla |
|---|---|---|
| `personalAmolHistorySection` | My Amol | আমার আমল |
| `personalAmolHistoryCompleted` | Completed | সম্পন্ন হয়েছে |
| `personalAmolHistoryNotCompleted` | Not completed | সম্পন্ন হয়নি |
| `personalAmolHistoryTotalLabel` | Times completed | মোট যতবার সম্পন্ন হয়েছে |
| `personalAmolSaveLabel` | Save | সেভ করুন |

*Fixed: `personalAmolHistoryTotalLabel` — English said "Completions" (a count) but Bangla said "সম্পন্ন" (Completed, a status). Both now clearly mean "how many times."*

---

## 11. Progress Row

| Key | English | Bangla |
|---|---|---|
| `personalAmolProgressLabel` | {done}/{total} completed | {done}/{total} সম্পন্ন |
| `personalAmolStreakLabel` | {n}-day streak | {n} দিনের স্ট্রিক |

---

## 12. Error / Loading

| Key | English | Bangla |
|---|---|---|
| `historyLoadFailed` *(shared)* | Couldn't load history. Try again. | হিস্টোরি লোড করা যায়নি। আবার চেষ্টা করুন। |

---

## Summary of judgment calls (flagging so you can override)

1. **"Personal Amol" → "My Amol" / "আমার আমল"** — biggest change, touches the section title, list title, and history section. If you'd rather keep "Personal Amol" as the brand name for this feature (e.g. it's referenced in marketing/App Store copy already), say so and I'll revert just this one and keep everything else.
2. **এডিট / ডিলিট / সেভ over সম্পাদনা / মুছে ফেলুন / সংরক্ষণ** — applied everywhere for consistency. This is the single biggest "sounds like a textbook" fix.
3. **Toggle → "Done / Not done" / "হ্যাঁ / না"** — much clearer than "Toggle" for non-technical users who don't know what tracking-type toggle even means.
4. Dropped "Please" / "অনুগ্রহ করে" from validation messages — direct and short, matches how bKash/Nagad phrase field errors.