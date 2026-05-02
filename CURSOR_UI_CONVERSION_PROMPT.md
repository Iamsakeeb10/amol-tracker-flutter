# Cursor Prompt: Convert All Provided HTML UI Screens to Flutter (UI Only)

You are working inside this Flutter project and must convert all provided HTML mockups into Flutter screens with reusable widgets, clean architecture, and working navigation for UI testing.

## Objective
Build **all UI screens only** from the provided HTML/MD specs, then wire navigation so I can run the app and manually navigate through every screen to verify UI.

## Strict Rules
- UI-only task: **do not implement business logic, backend, auth, firestore, hive, notifications, data persistence, or real calculations**.
- Use **mock/static data** only.
- Keep code clean, modular, and reusable.
- Reuse theme/colors/styles from existing project docs.
- Keep existing project runnable with `flutter run` and analyzable.
- Add minimal widget tests just to ensure app boots and key routes render.

## Source Files You Must Follow
- HTML UI specs:
  - `amol_tracker_ui_screens.html`
  - `amol_tracker_remaining_screens.html`
  - `amol_remaining_screens_batch1.html`
  - `amol_remaining_screens_batch2.html`
  - `amol_group_sheet_screen.html`
- Design/system docs:
  - `COLORS.md`
  - `USER_FLOW.md`
  - `DEVELOPMENT_GUIDE.md`
  - `ROUTER.md`

## Screens to Build (Complete)
Implement every screen listed below:
- `S-00` Sign In
- `S-01a` Onboarding Slide 1
- `S-01b` Onboarding Slide 2
- `S-01c` Onboarding Slide 3
- `S-02` Home / Daily Log
- `S-03` Leaderboard
- `S-04` History / Calendar
- `S-05` Friends & Activity Feed
- `S-06` Invite / Join Group
- `S-07` Notifications
- `S-08` Profile & Badges
- `S-09` Settings
- `S-10` Day Complete
- `S-11` Group Sheet View
- `S-12` Friend Profile
- `S-13` Day Detail (Read-only)
- `S-14` Group Manage
- `S-15` Empty State (new user/no friends)
- `S-16` Streak Freeze Modal (as bottom sheet or modal widget)
- `S-17` Quiet Hours

## Required Navigation Flow (UI Testing Focus)
Set up routes and screen-to-screen navigation with buttons/CTAs so all screens are reachable:
- Auth/onboarding flow: `S-00 -> S-01a -> S-01b -> S-01c -> S-02`
- Main tab structure (visual + routing): Home, History, Friends, More
- Accessible routes:
  - Home: `S-02`, `S-10`, `S-15`, `S-16`
  - History: `S-04`, `S-13`
  - Friends: `S-05`, `S-06`, `S-11`, `S-12`, `S-14`
  - More: `S-07`, `S-08`, `S-09`, `S-17`
- Add a temporary internal dev entry (debug screen or drawer/overlay menu) to jump to any screen quickly for QA.

## UI/Theme Requirements
Follow palette and visual language from `COLORS.md` and HTML:
- Emerald + Gold Islamic theme, soft cards, rounded corners, translucent surfaces.
- Preserve hierarchy, spacing rhythm, tags/pills, score chips, progress bars, badges, and bottom nav style.
- Respect screen-specific visual details from each HTML file.

Create a centralized theme system:
- `AppColors` (if not already in proper Dart file, create it).
- `AppTextStyles` and shared spacing/radius constants.
- Shared reusable components for repeated UI patterns.

## Reusable Widget Requirements
Extract and reuse components for repeated patterns, such as:
- custom scaffold/background shell
- top app bars and section headers
- bottom navigation
- card containers
- list rows (friend/activity/settings)
- toggle row and switch visuals
- amal row item
- stat card
- streak badge/pill
- avatar chip
- calendar day cell
- score/progress bar
- badge tile
- modal container

## File/Folder Structure to Create
Use this structure (adjust if small naming differences are needed, but stay consistent):
- `lib/core/theme/` (`colors.dart`, `text_styles.dart`, `theme.dart`)
- `lib/core/router/` (route constants + app router)
- `lib/features/auth/presentation/screens/`
- `lib/features/home/presentation/screens/`
- `lib/features/history/presentation/screens/`
- `lib/features/friends/presentation/screens/`
- `lib/features/leaderboard/presentation/screens/`
- `lib/features/notifications/presentation/screens/`
- `lib/features/profile/presentation/screens/`
- `lib/features/settings/presentation/screens/`
- `lib/shared/widgets/`
- `lib/shared/mock/` (all temporary static/mock data)

## Implementation Constraints
- No fake async delays unless needed for visual loading placeholders.
- No provider/bloc/state mgmt complexity for now; lightweight local state only where needed for UI interaction.
- No external API calls.
- Avoid unnecessary dependencies.
- Keep null-safety strict and analyzer clean.

## Minimal Interactivity (UI-only)
Implement only visual interactions needed to preview UI states:
- toggles changing appearance
- tab switching visuals
- opening modal (`S-16`)
- route navigation between screens
- simple calendar cell tap to open `S-13`
- basic CTA buttons wired to mock navigation targets

## Deliverables
1. All screens implemented in Flutter from the provided HTML specs.
2. Reusable widget library extracted.
3. Unified theme + colors applied.
4. Route map wired so every screen is reachable and testable.
5. App runs successfully.
6. `flutter analyze` passes.
7. Basic widget test(s) updated to verify app boots and one or two core routes render.

## Definition of Done Checklist
- [ ] Every screen `S-00` to `S-17` exists and matches provided UI closely.
- [ ] No business logic/backend implementation present.
- [ ] Navigation flow works for manual UI testing.
- [ ] Reusable widgets used instead of repeated screen-level copy-paste.
- [ ] Theme consistency across screens.
- [ ] Analyzer clean.
- [ ] App launches and navigates without runtime errors.

## Output Format Required From You (Cursor)
After coding, provide:
1. Summary of created files.
2. Route table with screen IDs and paths.
3. Reusable widgets list.
4. Any UI deviations from HTML (if unavoidable).
5. Commands run and results (`flutter analyze`, `flutter test`, `flutter run` status).
