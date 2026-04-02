# Implementation Plan: POS Transaction Logic (PLAN_002)

## 1. Core Logic Component: SalesCubit
We will implement a `SalesCubit` using the `flutter_bloc` package to manage the complex states of a transaction.

### 1.1 Cubit States
- `SalesInitial`: Empty invoice draft.
- `SalesScanning`: Looking up product/batch (loading state).
- `SalesActive`: Items added, subtotal calculated.
- `SalesPaymentPending`: Choosing payment type (Cash/Debt).
- `SalesCommitting`: Running the Atomic Transaction in SQLite.
- `SalesSuccess`: Invoice finalized, ready for thermal printing.
- `SalesError`: Rollback occurred, error message displayed.

## 2. Technical Implementation: Atomic Transaction
To satisfy **Constitution 3.1**, we will implement a `SalesRepository` that wraps the database operations in a single block.

### 2.1 Transaction Pseudocode (Drift)
```dart
Future<void> finalizeSale(Invoice invoice, List<InvoiceItem> items) async {
  return db.transaction(() async {
    // 1. Save Header
    await db.into(db.invoices).insert(invoice);
    
    for (var item in items) {
      // 2. Save Item Detail
      await db.into(db.invoiceItems).insert(item);
      
      // 3. Decrement Batch Table
      await (db.update(db.batches)..where((b) => b.id.equals(item.batchId)))
          .write(BatchesCompanion(quantity: Value(currentQty - item.qty)));
          
      // 4. Log Audit Movement
      await db.into(db.stockMovements).insert(StockMovement(...));
    }
    
    // 5. If DEBT, update Customer Balance
    if (invoice.paymentType == PaymentType.debt) {
       await db.updateCustomerBalance(invoice.customerId, invoice.totalAmt);
    }
  });
}
```

## 3. FEFO Search Algorithm (Logic Layer)
- **Method**: `allocateInventory(productId, requestedQty)`
- **Logic**:
  1. Fetch all non-expired batches for `productId` ordered by `expiryDate ASC`.
  2. Recursive or loop allocation logic to split quantity into `InvoiceItems` if the first batch is insufficient.
  3. Throw `InsufficientStockFailure` if total quantity in all batches < requested.

## 4. Error Handling & Rollback Verification
- Use `try-catch` blocks specifically in the `SalesRepository`.
- Any `DriftException` will automatically trigger a `rollback` in the `db.transaction` block.
- UI will show a **"Critical Error: Data Protected / No Changes Made"** message if rollback occurs.

## 5. Visual Planning Update
- Refer to `_planning/visuals/POS_TRANSACTION_SEQUENCE.md` as the implementation reference.
