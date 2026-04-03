# TASK_006: Invoice Review & Cancellation

## 1. Goal
Implementation of User Story 6 (View Invoice) and User Story 7 (Cancel Invoice) with full data integrity.

## 2. Micro-Tasks

### 🟢 Data Layer (Persistence)
- [x] **Task 6.1**: Implement `getInvoiceDetails(int invoiceId)` in `InvoiceDao`.
    - Join `InvoiceItems` with `Products` and `Batches` for a comprehensive view.
- [x] **Task 6.2**: Implement `cancelInvoice(int invoiceId)` in `InvoiceDao`.
    - Wrap in a transaction.
    - Set status to `CANCELED`.
    - Iterate through `InvoiceItems` and restore `Batch.quantity`.
    - Log `StockMovement` as `RETURN`.
    - Handle `Debt` reversal if applicable.

### 🟡 Logic Layer (State Management)
- [x] **Task 6.3**: Create/Extend `SalesCubit` to handle history and details.
    - `loadInvoice(int id)`: Emit detailed invoice state.
    - `cancelInvoice(int id)`: Trigger DAO cancellation and handle errors.

### 🟣 UI Layer (Interface)
- [x] **Task 6.4**: Build `InvoiceDetailDialog` component (Premium UI/UX).
    - **Vibe**: Professional Medical Dashboard (Clean, Trustworthy, High-Contrast).
    - **Header**: Sticky glassmorphism header with Invoice ID, Timestamp, and Dynamic Status Badge (Emerald/Rose/Amber).
    - **Body**: 
        - Interactive Item List: Use subtle cards instead of a raw table.
        - Visual Adjustments: Display "Discount" in muted red and "Premium" in soft blue with percentage badges.
        - Highlights: Auto-highlight expiring items within the invoice view.
    - **Footer**: 
        - Summarized Totals: Large, bold typography for the Grand Total.
        - Payment Metadata: Icon-based indicators for Cash/Bank/Debt.
    - **Micro-motions**: Add a subtle fade-in for details and a "Pulse" animation on the total amount.
- [x] **Task 6.5**: Implement "Cancel Sale" button logic.
    - Confirmation popup (Constitution §7.2 - Error Prevention).
    - Success/Error SnackBar notifications.

### 🔵 Integration & Verification
- [ ] **Task 6.6**: Integration Test.
    - Flow: Add items -> Complete Sale -> View Details -> Cancel Sale -> Verify Stock & Balance.
- [ ] **Task 6.7**: Documentation.
    - Update `TODO.md` in `lib_agent/.gsd/`.
