# MoveOn UI Redesign Implementation Plan

> **For agentic workers:** Use inline execution. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace default Material Design with "清爽自然风" forest-based visual identity across all screens.

**Architecture:** Centralized `MoveOnTheme` class in `lib/theme.dart` exporting all Design Tokens; `app.dart` applies `ThemeData`; screens reference tokens via `Theme.of(context)` or static constants.

**Tech Stack:** Flutter 3.x, Google Fonts (Noto Sans SC), Material 3

## Global Constraints
- All color values from spec §1.1–§1.2 verbatim
- All spacing/radius values from spec §1.4 verbatim
- 20% comment ratio maintained
- Build + tests must pass before each commit

---

## Tasks

### Task 1: Design Token foundation (`lib/theme.dart` + `app.dart`)

**Files:**
- Create: `lib/theme.dart`
- Modify: `lib/app.dart`
- Modify: `pubspec.yaml` (add `google_fonts`)

**Goal:** Centralized design tokens + updated ThemeData.

- [ ] Step 1: Add `google_fonts: ^6.1.0` to pubspec.yaml
- [ ] Step 2: Create `lib/theme.dart` with `MoveOnTheme` class
- [ ] Step 3: Rewrite `lib/app.dart` ThemeData using MoveOnTheme
- [ ] Step 4: `flutter pub get && flutter build windows --debug && flutter test`
- [ ] Step 5: Commit

### Task 2: Category model + follow home screen

**Files:**
- Modify: `lib/models/workout_category.dart` (add `backgroundColor`)
- Modify: `lib/screens/follow/follow_home_screen.dart`

**Goal:** 8 colored cards, new subtitle, icon styling.

- [ ] Step 1: Add `backgroundColor` field with defaults to WorkoutCategory
- [ ] Step 2: Rewrite _CategoryCard to use colored Container instead of Card
- [ ] Step 3: Add subtitle text "选择运动，开始跟练"
- [ ] Step 4: Build + test + commit

### Task 3: DIY screens + video player

**Files:**
- Modify: `lib/screens/diy/diy_home_screen.dart`
- Modify: `lib/screens/diy/module_execute_screen.dart`
- Modify: `lib/screens/follow/video_player_screen.dart`

**Goal:** Card color bars, FAB restyle, countdown area restyle, progress bar.

- [ ] Step 1: DIY list — add 4px color bar on card left
- [ ] Step 2: DIY list — restyle FAB (green, capsule shape)
- [ ] Step 3: Execute screen — countdown font → Noto Sans Mono, accent color at 5s
- [ ] Step 4: Execute screen — progress bar 6px green gradient
- [ ] Step 5: Execute screen — AnimatedSwitcher for action transitions
- [ ] Step 6: Video player — 6px green gradient progress bar
- [ ] Step 7: Build + test + commit

### Task 4: Navigation + profile

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/screens/profile/profile_home_screen.dart`

**Goal:** Bottom nav restyle, profile avatar + buttons.

- [ ] Step 1: Home screen — BottomNavigationBar restyle (64px, dot indicator, green color)
- [ ] Step 2: Profile — avatar with forest green gradient background
- [ ] Step 3: Profile — login button → filled green capsule
- [ ] Step 4: Profile — register button → outlined green capsule
- [ ] Step 5: Build + test + commit

### Task 5: Polish — remaining screens + transitions

**Files:**
- Modify: `lib/screens/diy/module_create_screen.dart`
- Modify: `lib/screens/diy/module_detail_screen.dart`
- Modify: `lib/screens/follow/video_list_screen.dart`
- Modify: `lib/screens/profile/login_screen.dart`
- Modify: `lib/screens/profile/register_screen.dart`
- Modify: `lib/screens/profile/change_password_screen.dart`

**Goal:** Consistent button styles, page transition animations.

- [ ] Step 1: Apply primary/secondary button styles to all auth screens
- [ ] Step 2: Apply page padding and card styling to remaining screens
- [ ] Step 3: Add page transition animation (slide up + fade, 200ms)
- [ ] Step 4: Build + test + commit
