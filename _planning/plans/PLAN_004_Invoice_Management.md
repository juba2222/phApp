# PLAN_004: Invoice Review & Cancellation Implementation

## 1. Feature Overview
Implementing the ability for a cashier/admin to review completed invoices (including item-level discounts/premiums) and cancel them, which includes a full stock reversal (Return) into the database.

## 2. Technical Stack
- **Database**: Drift (SQLite) with multi-batch logic.
- **State Management**: flutter_bloc (SalesCubit and a new HistoryCubit).
- **Architecture**: Clean Architecture (Data -> Domain/Logic -> UI).

## 3. Implementation Phases

### Phase 1: Persistence & Repository (Data Layer)
- **Goal**: Implement the core cancellation query and invoice retrieval.
- **Tasks**:
    - [x] (Already done) Update `InvoiceItems` table to include `suggestedPrice`.
    - [ ] Update `InvoiceDao` to include `getInvoiceDetails(int invoiceId)` which joins `InvoiceItems` with `Products` and `Batches`.
    - [ ] Update `InvoiceDao.cancelInvoice(int invoiceId)` to:
        - Use a `transaction`.
        - Mark `InvoicesTable.status` as `CANCELED`.
        - For each `InvoiceItem`:
            - Update corresponding `Batch.quantity` (+qty).
            - Insert `StockMovement` (type: `RETURN`).
        - If `DEBT`, find associated `Debt` record and reverse its effect on `Customer.totalDebt`.

### Phase 2: Logic & Events (Cubit Layer)
- **Goal**: Manage the lifecycle of viewing and canceling.
- **Tasks**:
    - [ ] Create `InvoiceHistoryCubit` (or extend `SalesCubit` if appropriate for "Recent Invoices").
    - [ ] Implement `loadInvoiceDetails(int id)`.
    - [ ] Implement `requestInvoiceCancellation(int id)`.

### Phase 3: Interface (UI Layer)
- **Goal**: User-friendly review and one-click cancellation.
- **Tasks**:
    - [ ] **Invoice Detail Dialog**:
        - List items with: Name, Qty, Final Price, Suggested Price (Difference in IDR/USD, and %).
        - Display Grand Total and Payment Method.
    - [ ] **Cancellation Integration**:
        - Add "Cancel Sale" button to the Detail Dialog (Admin/Cashier permission check - manual for now).
        - Add Confirmation Dialog with "Reason" input (optional).
        - Show SnackBar on success/fail.

## 4. Logic Flow: Cancellation Ceremony
1. User clicks "Cancel" -> UI triggers `requestInvoiceCancellation(id)`.
2. Cubit calls `InvoiceDao.cancelInvoice(id)`.
3. DB Transaction starts:
    - Lock records.
    - Status -> `CANCELED`.
    - Stocks -> Refill Batches -> Audit Log.
    - Commit.
4. UI refreshes to show "Canceled" status.

## 5. Verification & Testing
- **Manual Test**: Perform a sale, verify stock drops -> Cancel sale -> Verify stock restores to original batches.
- **Manual Test**: Verify Debt amount increases on sale, and decreases on cancellation.
- **Manual Test**: Verify Audit Log contains `RETURN` entries.
