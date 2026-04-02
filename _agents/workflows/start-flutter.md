---
description: Initialize a new Flutter project with the correct structure and premium configuration.
---

# /start-flutter

This workflow will initialize a new Flutter project in the current directory and set up our professional architecture.

// turbo
1. Run `flutter create . --org com.pharmafix --project-name pharma_fix` to initialize the project.
2. Add dependencies to `pubspec.yaml`:
   - `flutter_riverpod`
   - `dio`
   - `go_router`
   - `flutter_screenutil`
   - `lottie`
   - `freezed_annotation`
   - `json_annotation`
3. Add dev_dependencies:
   - `build_runner`
   - `freezed`
   - `json_serializable`
4. Run `flutter pub get`.
5. Create the base folders:
   - `lib/core/theme`
   - `lib/core/util`
   - `lib/core/widgets`
   - `lib/features`
6. Create a basic `lib/core/theme/app_theme.dart` with Material 3 and custom colors.
