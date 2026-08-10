Knowledge Battle --- Interest Validation Plan

Goal

Before spending weeks building the full Knowledge Battle feature, run acheap validation experiment that tells us one thing:

Do Amol Tracker users want Knowledge Battle?

The experiment should take roughly 1 hour to implement and run for2--3 weeks.

1. Dismissible Banner

Add a dismissible Knowledge Battle interest banner to theHome/Dashboard screen.

Banner placement

The preferred position is:

Home
↓
HomeReminderCard
↓
Knowledge Battle Interest Banner  ← ADD HERE
↓
Today's amal
↓
Amal list

Place the banner immediately after the existing HomeReminderCard andbefore the "Today's amal" section/list.

This position is preferred because:

It is visible on the main Home screen.

Users already visit this area regularly.

It doesn't interfere with the actual Amal tracking cards.

It separates promotional/validation content from the daily Amallist.

It doesn't unnecessarily push the most important "Today's progress"section higher/lower.

It gives the Knowledge Battle idea good visibility without making itlook like an Amal.

Design consistency

Do not create a completely new visual style for this banner.

Follow the existing Amol Tracker design system and UI patterns.

Reuse the existing card/container style where appropriate.

Match existing rounded corners, spacing, typography, borders,colors, shadows, and background treatment.

Follow the same horizontal padding and vertical spacing used byother Home cards.

Use existing theme colors rather than introducing new colors.

Use an appropriate existing icon style for the Knowledge Battleconcept.

Keep the card visually lighter than the primary daily-progresscontent.

Make the × close icon subtle and consistent with other dismissibleUI in the app.

Keep the Yes/No buttons consistent with the app's existing buttoncomponents.

Respect both light/dark themes if the app supports them.

Ensure the layout works properly for both Bangla and English text.

Reuse an existing Home card/banner component if one already fits therequirement.

The banner should feel like an existing Amol Tracker component, not anexternally added survey or advertisement.

Banner content --- বাংলা

Title:

শীঘ্রই আসছে: ফ্রেন্ডদের চ্যালেঞ্জ করুন 🏆

Description:

কুরআন, হাদিস, সীরাহ ও আরও অনেক বিষয়ে কুইজ ব্যাটেল --- মজার, দ্রুত, আরএকসাথে শেখার দারুণ একটা উপায়।

Buttons:

হ্যাঁনা

Add a small × close icon in the top-right corner.

Banner content --- English

Title:

Coming soon: Challenge your friends 🏆

Description:

Quiz battles on Quran, Hadith, Seerah & more --- quick, fun, and agreat way to learn together.

Buttons:

YesNo

The banner should use the user's existing app language automaticallythrough the existing localization system.

2. One-Time Display

The banner should be shown only once per user.

There are three possible actions:

User taps "হ্যাঁ / Yes"

Record:

response: "yes"

Then hide the banner permanently.

User taps "না / No"

Record:

response: "no"

Then hide the banner permanently.

User taps ×

Treat this as a dismissal without a Yes/No answer.

Record:

response: "dismissed"

Then hide the banner permanently.

This distinction is useful because:

Yes = explicit interest

No = explicit lack of interest

Close = user dismissed without giving an opinion

Do not treat a close as a No.

3. Firestore

Create a collection:

battleInterest

Use the user's UID as the document ID:

battleInterest/{uid}

Store:

{
  "uid": "...",
  "response": "yes",
  "respondedAt": "Timestamp",
  "locale": "bn"
}

Where response can only be:

yes
no
dismissed

This gives you one record per user and prevents duplicate responses.

Why store locale?

It's cheap to store and lets you later understand whether the responsediffers between Bangla and English users.

You don't need to store topic preferences.

Firestore as the source of truth

Use Firestore as the source of truth for the Admin UI counts.

For example:

battleInterest
├── user1 → yes
├── user2 → no
├── user3 → dismissed
└── user4 → yes

The Admin UI can calculate:

Interested     = count(response == "yes")
Not Interested = count(response == "no")
Dismissed      = count(response == "dismissed")

Analytics should be used for event analysis, trends, and experimentmeasurement, while Firestore remains the user-level source of truth.

4. Analytics

Since Analytics is already implemented in Amol Tracker, also track theexperiment using Analytics events.

Event 1 --- Banner shown

battle_teaser_impression

Parameter:

locale: bn / en

Event 2 --- Yes

battle_teaser_yes

Parameter:

locale: bn / en

Event 3 --- No

battle_teaser_no

Parameter:

locale: bn / en

Event 4 --- Close

battle_teaser_dismissed

Parameter:

locale: bn / en

Keep the event names simple and consistent.

Only fire battle_teaser_impression when the banner is actuallydisplayed to the user.

5. Why Use Both Firestore and Analytics?

Firestore

Use Firestore for individual users.

You can later identify:

"These users said Yes."

Those users can become your initial beta group.

Firestore is also the source of truth for the Admin UI'sYes/No/Dismissed counts.

Analytics

Use Analytics for overall experiment measurement.

It helps you understand:

How many users saw the banner

How many said Yes

How many said No

How many dismissed it

Interest rate

Bangla vs English response rate

Response trend over time

So:

Firestore = user-level data + Admin UI source of truth

Analytics = experiment-level data + trends

6. Admin UI

Add a simple Knowledge Battle card to the existing Admin Dashboard.

Example

┌─────────────────────────────────┐
│ 🏆 Knowledge Battle             │
│                                 │
│ 👀 Seen                         │
│ 1,240                           │
│                                 │
│ ✅ Interested                   │
│ 127                             │
│                                 │
│ ❌ Not Interested               │
│ 310                             │
│                                 │
│ ✕ Dismissed                     │
│ 803                             │
│                                 │
│ 📈 Interest Rate                │
│ 10.2%                           │
└─────────────────────────────────┘

The Interested count should be the most prominent metric.

Main metrics

Seen → users who were shown the banner

Interested → users who selected Yes

Not Interested → users who selected No

Dismissed → users who closed it without answering

Interest Rate → Yes ÷ Impressions

You can also calculate:

Yes/No Rate = Yes ÷ (Yes + No)

But the primary metric should remain:

Interest Rate = Yes ÷ Impressions

This tells you what percentage of exposed users showed explicitinterest.

Important

The Admin UI counts for Interested, Not Interested, and Dismissedshould come from Firestore.

For Seen/Impressions, use the Analytics measurement or a reliableimpression count maintained by the experiment implementation. Avoidassuming that Analytics and Firestore counts will always be identical.

7. Admin UI --- Optional User List

You don't need this initially, but it would be useful to have a small:

View Interested Users

button.

This shows users where:

response == "yes"

These users can later become your initial beta testers.

Don't build a complicated analytics dashboard for this experiment.

8. Localization

Add only the strings you actually need.

app_bn.arb

"battleTeaserTitle": "শীঘ্রই আসছে: ফ্রেন্ডদের চ্যালেঞ্জ করুন 🏆",
"battleTeaserSubtitle": "কুরআন, হাদিস, সীরাহ ও আরও অনেক বিষয়ে কুইজ ব্যাটেল — মজার, দ্রুত, আর একসাথে শেখার দারুণ একটা উপায়।",
"battleTeaserYes": "হ্যাঁ",
"battleTeaserNo": "না"

app_en.arb

"battleTeaserTitle": "Coming soon: Challenge your friends 🏆",
"battleTeaserSubtitle": "Quiz battles on Quran, Hadith, Seerah & more — quick, fun, and a great way to learn together.",
"battleTeaserYes": "Yes",
"battleTeaserNo": "No"

No confirmation string is necessary because the banner disappearsimmediately after the response.

No topic-related strings are necessary.

Don't manually edit:

app_localizations_bn.dart
app_localizations_en.dart

Run the normal:

flutter gen-l10n

process after modifying the ARB files.

9. Local "Already Shown" State

You need to make sure the banner only appears once.

A simple local flag is enough:

hasSeenBattleTeaser: true

Hive is fine since it is already being used.

Set it to true after:

Yes

No

Close

Recommended cross-device protection

Also use the Firestore document to make the one-time state reliableacross devices.

Before showing the banner:

Check whether battleInterest/{uid} already exists.

If it exists, don't show the banner.

If it doesn't exist, show the banner.

After Yes/No/Close, save the response and mark the banner as seen.

This prevents a user who changes devices from seeing the survey again.

The local Hive flag can still be used to avoid unnecessarychecks/re-rendering.

10. What to Measure

After 2--3 weeks, look at:

Metric          Meaning

Impressions     How many users saw the bannerYes             Explicit interestNo              Explicit lack of interestDismissed       Closed without answeringInterest rate   Yes ÷ impressionsYes/No rate     Yes ÷ (Yes + No)

The Yes count and Interest Rate are the most important metrics.

Sample size matters

Do not make the build decision based on percentage alone.

For example:

A 20% interest rate from 10 users is not as meaningful as a 10%interest rate from 1,000 users.

Always consider:

Total impressions

Total Yes responses

Total No responses

Total dismissed responses

How long the experiment has been running

11. Suggested Decision Threshold

Use these only as rough guidelines:

🟢 8--10%+ Yes rate

Strong enough signal to seriously consider building Knowledge Battle.

🟡 3--7%

Interesting but inconclusive.

Consider getting another signal before spending several weeks buildingit.

🔴 <3%

Weak demand.

Probably don't prioritize the feature yet.

These aren't universal industry benchmarks; they're simply practicalthresholds for this experiment.

Also consider the absolute number of interested users, not only thepercentage.

12. Testing Period

Run the experiment for 2--3 weeks.

At the end of the first week, check:

Banner appears in the correct position.

Banner only appears once.

Yes is recorded correctly.

No is recorded correctly.

Close is recorded correctly.

Firestore documents are created correctly.

Duplicate responses cannot be created.

Analytics events are firing.

Bangla and English localization work.

Admin counts are correct.

Interest rate is calculated correctly.

Banner follows the existing Home UI design pattern.

Banner works correctly across app restarts.

Firestore prevents the banner from reappearing on another device.

Don't make the final decision after only a few days unless the sample isalready very large.

13. Final User Flow

Home structure:

Home
↓
HomeReminderCard
↓
Knowledge Battle Banner
↓
Today's amal
↓
Amal list

Banner interaction:

          Knowledge Battle Banner
                    │
        ┌───────────┼───────────┐
        ↓           ↓           ↓
       YES          NO          ×
        │           │           │
        └───────────┼───────────┘
                    ↓
             Save response
                    +
             Analytics event
                    ↓
            Hide permanently

14. What You Should NOT Build Yet

For this validation phase, don't build:

Quiz Battle screen

Friend matchmaking

Question bank

Battle rooms

Leaderboards

Quiz UI

Topic selection

Notifications

Admin question management

Payment/monetization

Complex analytics dashboard

The entire purpose is to answer one question first:

"Do our users want Knowledge Battle?"

If the answer is strong, then start building the actual feature.

Recommended Architecture

                         HOME
                           │
                           ↓
                  HomeReminderCard
                           │
                           ↓
               Knowledge Battle Banner
                           │
                    ┌──────┼──────┐
                    ↓      ↓      ↓
                   YES     NO      ×
                    │      │      │
                    └──────┼──────┘
                           ↓
                     Firestore
                  battleInterest/{uid}
                           +
                       Analytics
                           ↓
                    Admin Dashboard
                           ↓
                  Yes / No / Dismissed
                           ↓
                    Build or Don't Build

Core Principle

Keep the implementation cheap and the UI native to Amol Tracker.

The banner should look and behave like it has always been part of theapp---not like a temporary survey bolted onto the Home screen.

The validation should answer one clear product question with the minimumamount of engineering:

Do Amol Tracker users want Knowledge Battle?