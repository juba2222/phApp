---
name: Flutter Professional Agent Skill
description: Expert instructions for building high-fidelity, high-performance Flutter applications with a clean architecture.
---

# Flutter Professional Skill

This skill extends your capabilities to build and maintain premium Flutter applications. Follow these instructions religiously for every Flutter task.

## 1. Project Structure (Clean Architecture)
Always organize the `lib/` directory using the following feature-based structure:
- `core/`: Global utilities, themes, constants, and shared widgets.
- `features/`: Divided by business feature (e.g., `auth`, `medication_entry`, `inventory`).
    - `feature_name/data/`: Models, Drows, repositories, and data sources.
    - `feature_name/domain/`: Entities and use cases.
    - `feature_name/presentation/`: UI (Screens and Widgets) and state management logic.

## 2. State Management Recommendations
- **Primary:** Riverpod (efficient, testable, and reactive).
- **Alternative:** Bloc/Cubit (for highly structured, event-driven state).
- **Simple:** Provider (for very small projects).

## 3. UI/UX & Styling (Premium Requirements)
- **Material 3:** Always enable `useMaterial3: true` in `ThemeData`.
- **Custom Theming:** Define a `MaterialColor` palette and a comprehensive `TextTheme` in `core/theme/`.
- **Aesthetics:**
    - Use smooth transitions (e.g., `page_transition`).
    - Add micro-animations using `Lottie` or Flutter's built-in `AnimatedContainer`.
    - Use gradients for primary UI elements to give a "Premium" look.

## 4. Key Packages to Always Consider
- `dio`: For networking.
- `riverpod` / `flutter_riverpod`: State management.
- `freezed` & `json_serializable`: For data models.
- `go_router`: For declarative routing.
- `flutter_screenutil`: For responsive UI.
- `shared_preferences` / `hive`: For local storage.

## 5. Development Workflow
- Always check `pubspec.yaml` before adding new dependencies to avoid version conflicts.
- Ensure all public methods and complex logic are documented.
- Use `flutter_lints` and follow Dart's official style guide.
