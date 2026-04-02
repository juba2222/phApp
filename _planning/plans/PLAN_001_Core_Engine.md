# Implementation Plan: Core Engine & POS (PLAN_001)

## 1. Technical Stack Selection (Offline-First)

| Tool | Purpose | Reason |
| :--- | :--- | :--- |
| **Flutter** | Frontend Framework | Productivity & Multi-platform. |
| **Drift (SQLite)** | Reactive Database | Strong typing, SQL reactivity, and transaction support. |
| **flutter_bloc** | State Management | Predictable state, easy to test. |
| **get_it** | Dependency Injection | Decentralized service management. |
| **injectable** | DI Generator | Automatic configuration for get_it. |
| **dio** | Networking | Robust API requests (future sync). |
| **decimal** | High Precision | Preventing floating-point errors (Cents/Fills). |

## 2. Project Folder Structure (Feature-First)

```text
lib/
├── core/                  # Cross-cutting concerns
│   ├── arch/              # Base classes (UseCases, Repositories)
│   ├── database/          # Drift database definition (Moor files)
│   ├── error/             # Exceptions and Failure handling
│   └── di/                # Dependency injection setup
├── features/              # Modular features
│   ├── pos/               # Sales & POS Module
│   │   ├── data/          # DAOs, Repositories implementations
│   │   ├── domain/        # Entities & UseCases (FEFO Logic)
│   │   └── presentation/  # Cubits & UI Widgets (Atomic Design)
│   ├── inventory/         # Product & Batch management
│   └── accounting/        # Debt & Payments
└── main.dart
```

## 3. Engineering the Data Layer (Drift)

### 3.1 SQLite Transaction Wrapper
We will implement a custom `DatabaseService` wrapper that enforces `DB.transaction(() async { ... })` for all POS finalizations to ensure atomicity as per **Constitution 3.1**.

### 3.2 FEFO Implementation (Query Level)
The database will have a specific DAO method:
```sql
-- Example Drift SQL (FEFO Batch Lookup)
SELECT * FROM batches 
WHERE product_id = :pId AND quantity > 0 AND expiry_date > :today 
ORDER BY expiry_date ASC;
```

## 4. State Management (BLoC/Cubit)

### 4.1 SalesCubit Phase
- `DraftState`: Accumulating items, selecting batches (FEFO).
- `PaymentState`: Validating Customer ID, calculating partial payments.
- `CommittingState`: Executing the Atomic Transaction.
- `Success/FailureState`: Handling Rollback feedback to the user.

## 5. Verification Plan
- **Unit Tests**: Test FEFO logic with mock batches.
- **Integration Tests**: Verify database rollback when one table fails to insert.
- **Performance Test**: Measure "Add to List" speed for POS under 300ms.
