Yes. For this change, I’d treat the quiz as a state machine rather than simply adding two buttons. The important edge cases are around question navigation, answer state, and the battle’s completion/submission rules.

1. Navigation boundaries
First question
Previous button disabled/hidden.
Tapping Previous must never produce index -1.
Last question
Next button should either:
become Finish/Submit, or
be disabled until the expected answer/action is completed.
Never navigate beyond the final question.
Single-question quiz
Both boundary conditions apply simultaneously.
Previous disabled; Next becomes Finish.
2. Answer state when moving around

This is probably the most important one.

If the user:

opens Q1
selects option B
goes Next → Q2
goes Previous → Q1

Q1 should still show B as selected.

Also handle:

unanswered → answered
answered → revisit
answered → change answer
answered → navigate away → return
multiple questions with different answer states

I'd keep something like:

Map<QuestionId, SelectedAnswer>

rather than relying only on the currently displayed question's state.

3. Remove automatic navigation

After selecting an option:

Do not automatically move to the next question.
Selecting an option should only update the answer state.
Navigation should happen exclusively through Next/Previous.

This also prevents accidental skipping caused by a tap.

4. What does "Skip" mean?

You should define this explicitly.

If the user presses Next without selecting an answer:

allow navigation to the next question
leave the current question unanswered

Then at the end, decide whether unanswered questions are allowed.

For example:

Q1 answered → Q2 skipped → Q3 answered → Finish

The system should preserve Q2 as unanswered.

5. Finishing with unanswered questions

On the final question, consider:

0 unanswered → submit immediately
some unanswered → show confirmation:
"You have 3 unanswered questions. Finish anyway?"
optionally provide a way to jump back to unanswered questions

This is especially useful for a battle/quiz flow.

6. Changing an existing answer

If the user goes back and changes an answer:

replace the previous selection
don't create duplicate answers
scoring should use the latest selected answer

Example:

Q1: A
Previous
Q1: C

Final answer must be C.

7. Scoring timing

Be careful not to calculate the score when the user taps an option.

Instead, calculate the final result from the stored answers when the battle is submitted.

Otherwise changing an answer later can create problems such as:

+1 for A
change A → B
+1 for B

which could incorrectly produce 2.

8. Rapid taps / double taps

Handle fast repeated taps on:

Next
Previous
Finish/Submit

For example:

Next → Next → Next

shouldn't accidentally skip two or three questions because of multiple queued events.

Similarly, Finish should only submit once.

A simple navigation guard/loading state can help.

9. Async operations

If selecting an answer or submitting the battle involves an API/database call, consider:

user presses Next while save is in progress
user presses Previous while save is in progress
user leaves the screen during the operation
API failure
API timeout
duplicate submission

Ideally navigation shouldn't depend on a fragile asynchronous answer-save operation unless your backend requires it.

10. State restoration

If the widget rebuilds because of:

setState
provider/bloc state changes
orientation change
parent rebuild
localization change

the current question and selected answers shouldn't unexpectedly reset.

In particular, avoid storing the current index in a place that gets recreated during rebuilds.

11. Battle-specific edge cases

Since this is a battle, I'd additionally consider:

opponent finishes before the user
battle timer expires while user is on a question
timer expires while moving between questions
battle is cancelled
battle becomes invalid/expired
network disconnects
app goes to background
app is killed and reopened
battle submission succeeds but the UI doesn't receive the response
user presses Finish after submission already happened

The timer case is particularly important: timer expiry should have one authoritative path to finish the battle, regardless of which question is currently displayed.

12. Localization

For the new buttons, don't hardcode:

Text('Next')
Text('Previous')

Add localization keys such as:

battle.next
battle.previous
battle.finish
battle.unansweredQuestions
battle.finishConfirmation

Also consider longer translations. A button that fits "Next" may not fit the equivalent translation in another language.

So use layouts that can accommodate varying text lengths rather than fixed-width buttons.

13. Accessibility

Check:

buttons have semantic labels
disabled state is communicated
selected answer is accessible
touch targets are sufficiently large
keyboard/DPAD navigation if relevant
text doesn't overflow in localized languages
14. Back navigation

Decide what happens when the user presses the system/app back button.

Possible behavior:

Back
 ↓
Are you sure you want to leave the battle?
 ↓
Leave / Stay

You generally don't want an accidental back gesture to silently abandon a battle.

15. Question list / progress indicator

If you have something like:

Question 3 / 10

make sure it stays synchronized with the actual index.

Even better, show answered state:

✓  ✓  —  ✓  —  —  ...

Then users can understand that Previous/Next navigation doesn't mean they have to answer every question sequentially.

The core behavior I'd recommend
                 ┌──────────────┐
                 │ Current Q    │
                 └──────┬───────┘
                        │
              select option
                        │
                        ▼
                 save answer
                        │
                   stay on Q
                        │
          ┌─────────────┴─────────────┐
          │                           │
       Previous                     Next
          │                           │
          ▼                           ▼
   index > 0 ?                 index < last ?
          │                           │
      previous                    next question
                                      │
                                      ▼
                               last question?
                                      │
                                yes → Finish

The key design principle is:

Answer selection and question navigation should be two separate actions.

That separation makes skipped questions, revisiting questions, changing answers, scoring, and battle completion much easier to reason about.

My priority order

I'd make sure these are covered before considering the feature complete:

Previous on first question
Next/Finish on last question
Skipped unanswered questions
Persist answers when navigating back
Changing an existing answer
Correct final scoring after changes
Finish with unanswered questions
Double-tap protection
Timer/battle expiry
Submission/API failure
Back navigation
Localization overflow