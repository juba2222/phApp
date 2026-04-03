# PharmaFix Project Architecture & Constitution

This document is the **OFFICIAL CONSTITUTION** and architecture guide for **PharmaFix**. All development MUST adhere to these non-negotiable principles.

---

## 1. Core Principles

### 1.1 Business Critical Accuracy
- All financial, inventory, and transaction data MUST be accurate and consistent.
- No operation may result in silent data loss or inconsistency.

### 1.2 Offline-First Operation
- The system MUST operate fully offline.
- All actions MUST be queueable and sync automatically when connection is restored.
- Conflict resolution MUST be deterministic.

### 1.3 Performance First (POS Priority)
- POS operations MUST complete in < 300ms.
- Barcode scanning MUST be instant and not blocked by network.

### 1.4 Simplicity Over Complexity
- UI and workflows MUST be minimal and optimized for speed.
- Avoid unnecessary steps in selling and inventory operations.

---

## 2. Structural Architecture (Clean Architecture)

We follow a strict **Clean Architecture** pattern to ensure the app is testable, maintainable, and independent of external agencies (like the database or UI library).

### 2.1 The Layers
- **Data Layer (Outside)**:
  - Responsible for data retrieval from APIs or Local Database (Drift).
  - Contains: DataSources (Local/Remote), Repository Implementations, and DTOs (Models).
- **Domain Layer (Center - Pure Dart)**:
  - The business logic "core". No Flutter dependencies allowed here.
  - Contains: Entities (Plain Data Classes), Use Cases (Individual business actions), and Repository Interfaces.
- **Presentation Layer (Inside)**:
  - The Flutter UI and State Management.
  - Contains: Screens, Widgets (Atomic UI), and State Managers (Cubit/BLoC/Riverpod).

### 2.2 Feature-First Structure
Projects are structured by **Features**, not by file type. This keeps related code together.
```text
lib/
 ├── features/
 │   ├── auth/
 │   │   ├── data/
 │   │   ├── domain/
 │   │   └── presentation/ (screens & widgets)
 │   └── pos/
 ├── core/ (Shared components: theme, colors, network_info, etc.)
 └── main.dart
```

---

## 3. Flutter Implementation Standards

### 3.1 State Management
- **Primary Options**: **BLoC/Cubit** or **Riverpod**.
- **STRICT RULE**: The `build` method is for UI declaration ONLY.
- **No Logic in UI**: Calculations, data fetching, or input validation MUST happen in the Controller/BLoC layer.

### 3.2 Atomic Widgets (The "100-Line" Rule)
- To prevent "Code Jungles", widgets MUST be small.
- **Limit**: If a Widget exceeds 60-100 lines, extract its parts into separate files.
- Feature-specific widgets stay in `feature/presentation/widgets/`.
- Reusable system widgets go to `core/widgets/`.

### 3.3 Data Integrity & Models
- **No Maps**: Use strictly typed Classes/Entities for all data.
- **Code Generation**: Use `freezed` or `json_serializable` for boilerplate reduction.
- **Repositories**: Acts as a buffer between UI and Data. UI should never know if data comes from SQLite or a REST API.

### 3.4 Logic Isolation
- **Extensions**: Use Dart Extensions for common formatting (e.g., `dateTime.toRelative()`).
- **Mixins**: Use Mixins for shared behavior (e.g., `LoadingStateMixin`).
- **DI**: Use `get_it` for Dependency Injection to decouple classes.

---

## 4. Coding Standards & Quality

### 4.1 Clean Code
- **Naming**: Variables and functions must have self-describing names.
- **Comments**: Describe the **WHY**, not the **WHAT**.
- **Linting**: Maintain a strict `analysis_options.yaml`. Fix all warnings immediately.

### 4.2 Transaction Safety
- All financial operations MUST be atomic (wrapped in database transactions).
- No partial writes are allowed.

### 4.3 Auditability
- Every critical action MUST be logged (Sales, Purchases, Edits, Deletes).

---

## 5. Roles & Permissions

- **Admin**: Full access to financial history, settings, and stock management.
- **Cashier**: Restricted to Sales flow. Cannot edit finalized invoices or sensitive stock data.

---

## 6. Constraints

- No feature may violate the **Offline-First** principle.
- No feature may bypass **Audit Logging**.
- No UI may compromise **POS Performance** (Instant responsiveness).

---

## 7. Evolution Rules

- Constitution changes MUST be rare and justified.
- Every change MUST be evaluated against: Data Integrity, Performance, and Offline capability.
