# SPEC_004: Invoice Review & Cancellation

## 1. Overview
This specification covers the post-transaction lifecycle of an invoice: viewing its details for verification and the ability to cancel it with full inventory reconciliation.

## 2. User Stories
### User Story 6: View Invoice Details
**As a** Cashier  
**I want** to see the full details of an invoice (products, quantities, prices, total, and payment type)  
**So that** I can verify the transaction's correctness.

### User Story 7: Cancel Invoice
**As a** Cashier / Admin  
**I want** to cancel an invoice after it has been created  
**So that** I can correct mistakes or handle returns.

## 3. Functional Requirements

### 3.1 Invoice Detail View
- **Data Display**:
    - List of products included in the invoice.
    - Quantity for each product.
    - Unit Price and Subtotal per item.
    - **Adjustment Analysis**: Show discount or premium amount/percentage per item (Price Difference from Suggested Price).
    - Grand Total of the invoice.
    - Payment Type (CASH, BANK, DEBT).
    - Customer Name (if applicable).
    - Date and Time of transaction.
- **Access Points**: 
    - Immediately after a sale (Success Screen).
    - From a "Sales History" or "Recent Invoices" list (to be implemented).

### 3.2 Invoice Cancellation
- **Action**: A clearly visible "Cancel Invoice" button within the detail view.
- **Inventory Reconciliation**:
    - When an invoice is canceled, the system MUST automatically increment the quantities in the original Batches (FEFO restoration).
    - This ensures stock accuracy without manual adjustment.
- **Transaction Reversal**:
    - The invoice status MUST be updated to `CANCELED`.
    - If the sale was `DEBT`, the associated debt record MUST be marked as `VOID` or its amount subtracted from the customer's total debt.
- **Audit Logging**:
    - A "Cancel" event MUST be logged in the system log/audit trail.
    - Optional: Selection of a reason (e.g., "Mistake", "Customer Return", "Technical Error").

## 4. Technical Implementation

### 4.1 Database Layer (Drift)
- `Invoices`: Ensure `status` column handles `CANCELED` (already exists in schema).
- `StocksMovements`: Insert a new record with type `RETURN` for each item restored to stock.

### 4.2 Logic Layer (Bloc/Cubit)
- `InvoiceDao.cancelInvoice(int invoiceId)`:
    - Wrap in a `transaction`.
    - Retrieve all `InvoiceItems` for the `invoiceId`.
    - For each item:
        - Increment matching `Batch.quantity`.
        - Log `StockMovement` as `RETURN`.
    - Update `InvoicesTable` status to `CANCELED`.
    - Update `Customers` debt if applicable.

### 4.3 UI Layer (Flutter)
- A new `InvoiceDetailDialog` or Screen.
- A "Cancel Sale" button with a confirmation popup ("Are you sure? This will restore stock.").

## 5. Constraints & Constitution Alignment
- **Constitution §3.1 (Transaction Safety)**: Cancellation MUST be an atomic database operation.
- **Constitution §3.2 (Auditability)**: Every cancellation MUST lead to a `RETURN` log entry.
- **Constitution §4.2 (Stock Accuracy)**: Stock MUST be restored to exactly the same batches to maintain FEFO integrity.
- **Constitution §5.2 (Sales Integrity)**: Invoices are never deleted from the DB; only their status is changed to `CANCELED`.
