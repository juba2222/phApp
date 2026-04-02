# Task 002: Theme & Design System Foundation

**Status**: [ ] Not Started
**Roadmap Reference**: Stage 1.3 - Theme Engine.

## Objectives
1. Implement a system-wide theme (Dark/Light) using Material 3.
2. Define a premium color palette (Pharma-themed: Teal, Clean White, Soft Gray).
3. Set up Typography for Arabic and English (Inter/Roboto for En, Cairo/Tajawal for Ar).

## Steps
1. [ ] Create `lib/core/theme/app_colors.dart`:
    - `primary`: Modern Teal.
    - `secondary`: Clean Emerald.
    - `surface`: Off-white (Light) / Deep Gray (Dark).
2. [ ] Create `lib/core/theme/app_typography.dart`:
    - Responsive text scales.
3. [ ] Implement `lib/core/theme/app_theme.dart`:
    - `ThemeData` for Light and Dark modes.
    - Button styles (Elevated, Filled, Tonal).
    - Input Decoration (Modern, rounded, subtle borders).

## Success Criteria
- [ ] App switches between Dark/Light mode correctly.
- [ ] UI elements (Buttons, Text) follow the defined palette.
- [ ] Arabic and English fonts load properly.
