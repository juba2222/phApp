# Task List: Database Layer & Data Models (TASK_003)

## 1. Environment Setup & Dependencies
- [x] Add `drift`, `drift_dev`, `sqlite3_flutter_libs`, `path_provider` to `pubspec.yaml`.
- [x] Add `injectable`, `get_it`, `build_runner` for dependency injection.
- [x] Add `decimal` package for high-precision financial calculations.
- [ ] Initialize `injectable` and `get_it` in `lib/core/di/`.

## 2. Drift Database Implementation
- [x] Create `AppDatabase` class in `lib/core/database/`.
- [x] **Table: Products**: `id`, `name`, `barcode`, `sell_price`, `base_price`.
- [x] **Table: Batches**: `id`, `product_id`, `batch_num`, `expiry_date`, `quantity`.
- [x] **Table: Invoices**: `id`, `customer_id`, `total_amt`, `payment_type`, `status`, `created_at`.
- [x] **Table: InvoiceItems**: `invoice_id`, `product_id`, `batch_id`, `qty`, `price_at_sale`.
- [x] **Table: StockMovements**: `id`, `type`, `product_id`, `batch_id`, `qty_change`, `ref_id`.

## 3. Data Access Objects (DAOs) & Logic
- [x] **BatchDao**: Implement `getFefoBatches(productId)` - Order by `expiry_date ASC`.
- [x] **InvoiceDao**: Implement `executeAtomicSale()` + `cancelInvoice()` - Full Atomic Transactions.
- [ ] **CustomerDao**: Implement simple debt balance calculation query.

## 4. Verification & Testing
- [ ] Run `build_runner` to generate drift code.
- [ ] Create Unit Test to verify FEFO query logic.
- [ ] Create Integration Test to verify **database rollback** on transaction failure.

## 5. Master Plan Sync
- [ ] Mark "Database Layer" as IN_PROGRESS in `_planning/MASTER_PLAN.md`.
