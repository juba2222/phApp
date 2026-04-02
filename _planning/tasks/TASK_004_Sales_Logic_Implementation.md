# Task List: POS Sales Logic & Repository (TASK_004)

## 1. Foundation: State & Repository Interface
- [ ] Define `SalesState` (Initial, Scanning, Active, Committing, Success, Error).
- [ ] Define `SalesCubit` in `features/pos/presentation/cubit/`.
- [ ] Create `ISalesRepository` interface in `features/pos/domain/repositories/`.

## 2. Core Business Logic (Domain Layer)
- [ ] Implement **FEFO Allocation Service**:
    - Input: `productId`, `requestedQty`.
    - Output: `List<AllocatedBatchItem>`.
    - Logic: Correct order by expiry, handling quantity split.
- [ ] Implement `InvoiceCalculator`: Total amt, Tax, Discounts.

## 3. Data Layer Implementation (Repository)
- [ ] Implement `SalesRepository` in `features/pos/data/repositories/`.
- [ ] Implement **`executeAtomicSale()`** using `db.transaction()`:
    - [ ] `Invoice` insertion.
    - [ ] Multiple `InvoiceItem` insertions (linked to batches).
    - [ ] `Batch` quantity decrement.
    - [ ] Creation of `StockMovement` logs for every item.
    - [ ] **Verification**: Ensure rollback triggers and prevents inconsistency.

## 4. Payment & Debt Integration
- [ ] Validate `customerId` is provided when PaymentType is `DEBT`.
- [ ] Update `Customer` balance within the core database transaction.
- [ ] Update `Debt` table (total, paid, remaining balance).

## 5. Visual Feedback & Logging
- [ ] Handle expiry warnings for the UI (e.g. "Item expires in 30 days").
- [ ] Ensure all `StockMovement` records correctly record `type: SALE`.

## 6. Testing (Verification Step)
- [ ] Write Unit Test: Split 10 items across 3 batches with different expiries.
- [ ] Write Integration Test: Force a failure in StockMovement insertion to verify Batch rollback.
