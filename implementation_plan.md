# Fix Community Screen Zero Values Bug

The problem occurs when a user navigates to a specific date in the Community Screen, and their own log values display as all zeros. 
This happens because the community feed only fetches the top 20 logs (sorted by score) for the selected date. If the user's score isn't in the top 20, their log is absent from the fetched data. The UI then incorrectly falls back to `_buildOwnPlaceholder`, which generates a mock log with all toggles set to `0` / `false`. 

## User Review Required
No breaking changes or major design decisions. Just fixing a data hydration bug.

## Proposed Changes

### `lib/providers/history_provider.dart`
#### [MODIFY] `history_provider.dart`
- Make `dayDetailLogProvider` watch `amalLogRefreshProvider`. This will ensure that if the user submits or edits their daily log, the provider invalidates and fetches the most up-to-date log from Firestore or the local cache.

### `lib/features/community/presentation/screens/community_screen.dart`
#### [MODIFY] `community_screen.dart`
- In `_CommunityScreenState.build` and `_CommunitySheetFullScreenState.build`, watch `dayDetailLogProvider` to explicitly fetch the current user's log for the selected date.
- Merge the explicit log with the `state.ownRow` (which is pulled from the top 20 community logs). If the user is not in the top 20, we will now fall back to their explicit log instead of `_buildOwnPlaceholder`.
- If both exist, use the one with the higher `editCount` or default to the explicitly fetched log to guarantee accuracy.

## Verification Plan
### Manual Verification
- Open the application and go to the Community Screen.
- Select a past date where you have submitted a log but your score is not in the top 20 for that day.
- Verify that your pinned log at the top correctly displays your logged values (e.g., Fard, Takbir, Quran) instead of all zeros or empty checkboxes.
