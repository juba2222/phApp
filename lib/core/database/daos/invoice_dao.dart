import 'package:drift/drift.dart' hide Batch;
import '../app_database.dart';
import '../tables/tables.dart';

part 'invoice_dao.g.dart';

@DriftAccessor(tables: [Invoices, InvoiceItems, StockMovements, Debts, Batches, Customers])
class InvoiceDao extends DatabaseAccessor<AppDatabase> with _$InvoiceDaoMixin {
  InvoiceDao(super.db);

  /// ATOMIC TRANSACTION: Finalize a sale (SPEC_003 §1.4 - Constitution §3.1).
  /// If any step fails, the ENTIRE transaction is rolled back.
  Future<void> executeAtomicSale({
    required InvoicesCompanion invoiceData,
    required List<InvoiceItemsCompanion> items,
    required List<BatchesCompanion> batchUpdates,
    DebtsCompanion? debtData,
  }) {
    return db.transaction(() async {
      // Step 1: Save Invoice Header
      final invoiceId = await into(db.invoices).insert(invoiceData);

      for (int i = 0; i < items.length; i++) {
        final item = items[i].copyWith(invoiceId: Value(invoiceId));
        final batchUpdate = batchUpdates[i];

        // Step 2: Save InvoiceItem (linked to specific Batch for FEFO accuracy)
        await into(db.invoiceItems).insert(item);

        // Step 3: Decrement Batch Quantity (FEFO-aware)
        final bTable = db.batches;
        await (update(bTable)..where((t) => t.id.equals(batchUpdate.id.value)))
            .write(BatchesCompanion.custom(
          quantity: bTable.quantity - Variable(item.qty.value),
        ));

        // Step 4: Log Stock Movement (Audit Trail - Constitution §3.2)
        await into(db.stockMovements).insert(
          StockMovementsCompanion(
            type: const Value('SALE'),
            productId: item.productId,
            batchId: item.batchId,
            qtyChange: Value(-(item.qty.value)), // Negative: Stock decreased
            referenceId: Value(invoiceId),
          ),
        );
      }

      // Step 5: Handle Debt
      if (debtData != null) {
        await into(db.debts).insert(debtData.copyWith(invoiceId: Value(invoiceId)));
        
        // Update Customer Total Debt
        final cTable = db.customers;
        final unpaid = debtData.amountTotal.value - debtData.amountPaid.value;
        await (update(cTable)..where((t) => t.id.equals(debtData.customerId.value)))
            .write(CustomersCompanion.custom(
          totalDebt: cTable.totalDebt + Variable(unpaid),
        ));
      }
    });
  }

  /// Cancel an invoice: Set status to CANCELED & restore batch quantities.
  Future<void> cancelInvoice(int invoiceId) {
    return db.transaction(() async {
      // Step 1: Get all Items from this Invoice
      final items = await (select(db.invoiceItems)
            ..where((i) => i.invoiceId.equals(invoiceId)))
          .get();

      for (final item in items) {
        // Step 2: Restore Batch Quantity (Return Logic)
        final bTable = db.batches;
        await (update(bTable)..where((t) => t.id.equals(item.batchId)))
            .write(BatchesCompanion.custom(
          quantity: bTable.quantity + Variable(item.qty), // Positive: Stock restored
        ));

        // Step 3: Log RETURN Movement
        await into(db.stockMovements).insert(
          StockMovementsCompanion(
            type: const Value('RETURN'),
            productId: Value(item.productId),
            batchId: Value(item.batchId),
            qtyChange: Value(item.qty), // Positive: Stock increased
            referenceId: Value(invoiceId),
          ),
        );
      }

      // Step 4: Mark Invoice as CANCELED
      await (update(db.invoices)..where((i) => i.id.equals(invoiceId)))
          .write(const InvoicesCompanion(status: Value('CANCELED')));
    });
  }
}
