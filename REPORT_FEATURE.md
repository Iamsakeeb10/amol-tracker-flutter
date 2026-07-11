What the Report Should Show
Before designing, let's define what data goes in each report type:
Weekly Report

Week date range (Hijri + Gregorian)
Total days logged vs missed
Average daily score
Best day of the week
Each amal completion rate (e.g. Fard: 6/7 days)
Streak status
Community rank that week
Hadith of the week

Monthly Report

Hijri month name + year
Total days logged
Consistency percentage
Average score
Best streak that month
Weakest amal (most missed)
Strongest amal (most completed)
Score trend graph (bar chart)
Top performer comparison

Custom Report

User picks start date → end date (Hijri calendar picker)
Same metrics as monthly but for chosen range
Maximum range: 90 days (beyond that gets slow)

User Flow
Profile / More screen
│
tap "My Reports"
│
▼
Reports Screen
│
├── Default shown: Current Week
│
├── Tabs: Weekly | Monthly | Custom
│
├── Date navigator: ← previous | current | next →
│ (for weekly: previous/next week)
│ (for monthly: previous/next month)
│ (for custom: date range picker)
│
├── Report card renders below
│
└── Bottom bar: [Share] [Download PDF]
