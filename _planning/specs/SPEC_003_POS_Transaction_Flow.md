# Specification: POS Transaction Flow (SPEC_003)

## 1. Step-by-Step Flow

### 1.1 Item Identification & Batch Selection (FEFO)
1. **Trigger**: Scanning a barcode or manual search.
2. **Logic**:
   - Query `Product` by barcode.
   - Query all active `Batch` records for this product where `quantity > 0` AND NOT expired.
   - **Sort**: Order by `expiry_date` (Ascending).
   - **Allocation**: Select the earliest expiring batch. If the batch doesn't satisfy the full order quantity, split the line item across multiple batches (e.g., 2 from April batch, 3 from June batch).

### 1.2 Sales Drafting
- UI displays product name, applied batch(es) expiry date, unit price, and subtotal.
- Removing an item from the draft releases the "reserved" logic (in-memory only until final save).

### 1.3 Finalization & Payment
- **Action**: Click "Complete Sale".
- **Step**: Validate `payment_type`.
  - If **DEBT**, verify that a `Customer` is selected.
  - If **CASH/BANK**, record reference IDs if needed.

### 1.4 Database Commit (Atomic Transaction)
According to **Constitution 3.1**, the final save MUST be an atomic transaction:
1. `INSERT Invoice` record.
2. `INSERT InvoiceItem` records (linked to specific batches).
3. `UPDATE Batch` quantities (decrement).
4. `INSERT StockMovement` records for audit logging.
5. `UPDATE Customer` balance (only if DEBT).

## 2. Rollback & Error Handling

### 2.1 Database Failure
- If any step in the Commit fails (e.g., integrity violation, out-of-storage), the system MUST trigger a **ROLLBACK**.
- No partial invoices or ghost stock movements are allowed.

### 2.2 Edge Cases
- **Expired while scanning**: System MUST block sales of medicine that passed its expiry date.
- **Stock mismatch**: If another POS terminal sold the same batch 1 second before (Race Condition), catch the "Negative Quantity Constraint" and re-trigger FEFO selection.

## 3. Constitutional Verification
- **Speed**: Batch selection query must be indexed on `expiry_date` to meet the < 300ms requirement.
- **Safety**: Audit logs must be created *inside* the same transaction as the sale.
