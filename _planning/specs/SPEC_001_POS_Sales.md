# Specification: POS Sales System (SPEC_001 - Improved)

## 1. Feature Overview
The Point of Sale (POS) is the primary module for retail transactions. It acts as an orchestrator between the UI, the Inventory (Batches), the Customer accounts (Debts), and the Audit system (StockMovements).

## 2. Advanced Functional Requirements

### 2.1 Smart FEFO Product Selection
- When a `Product` is added to the sale (Barcode/Search):
  1. The system MUST query all active `Batch` records for the product.
  2. Implement **Auto-Split Logic**: If the first expiring batch quantity $< N$ (requested quantity), the system automatically creates multiple `InvoiceItem` records, drawing from sequential batches until the quantity is satisfied.
  3. **Visual Feedback**: The UI MUST display the expiry date(s) of the allocated batch(es) for each line item.

### 2.2 Payment & Debt Integration
- **Payment Types**: CASH, BANK, DEBT.
- **Partial Payments Logic**:
  - If a sale is partially paid, the `payment_type` is recorded, but the remainder is automatically converted into a `Debt` record linked to a `Customer`.
  - **Invoice Status Update**:
    - Full payment: `COMPLETED`.
    - Partial/Zero payment: `PARTIAL_PAID` or `PENDING` (depending on debt amount).
- **Customer Mandatory**: A `customer_id` is MANDATORY for any transaction involving `payment_type == DEBT` or partial payment.

### 2.3 Robust Cancellation (Status: CANCELED)
- To maintain audit integrity, invoices are NEVER deleted. Instead:
  1. `Invoice.status` is set to `CANCELED`.
  2. For every `InvoiceItem` in the original invoice, the system MUST:
     - Generate a `StockMovement` record of type `RETURN`.
     - Restore (increment) the `quantity` in the original `Batch` record.
  3. If a linked `Debt` exists, it MUST be voided or adjusted.

### 2.4 Inventory & Audit Trail
- Every finalized sale MUST generate a series of `StockMovement` records (type: `SALE`) linked to each `Batch` utilized.
- All movements must record `performed_by` (Employee ID) for accountability.

## 3. Data Integrity & Constraints (Constitution Check)

### 3.1 Atomic Database Transactions
Per **Constitution 3.1**, the "Finalize Sale" action MUST be wrapped in a single database transaction (Unit of Work). 
- If the `Invoice` save fails, the `Batch` updates and `StockMovements` MUST ROLLBACK.
- Inventory levels MUST NOT decrease unless an invoice is successfully persisted.

### 3.2 Offline-First Performance
- Lookups for `Product` and `Batch` must be indexed (O(1) or O(log n)) to ensure the **< 300ms** performance rule for POS scanners.
- The local SQLite database stores all data; synchronization happens in the background.

## 4. Visual Reference
- Logic Flow: `_planning/visuals/POS_FLOW.md`
- Transaction Sequence: `_planning/visuals/POS_TRANSACTION_SEQUENCE.md`
- Data Model: `_planning/visuals/DATA_MODEL_ERD.md`
