import 'package:drift/drift.dart' hide Batch;
import '../app_database.dart';
import '../tables/tables.dart';

part 'invoice_dao.g.dart';

@DriftAccessor(tables: [Invoices, InvoiceItems, StockMovements, Debts, Batches, Customers])
class InvoiceDao extends DatabaseAccessor<AppDatabase> with _$InvoiceDaoMixin {
  InvoiceDao(super.db);

  /// ATOMIC TRANSACTION: Finalize a sale (SPEC_003 §1.4 - Constitution §3.1).
  /// If any step fails, the ENTIRE transaction is rolled back.
  Future<int> executeAtomicSale({
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
      
      return invoiceId;
    });
  }

  /// Retrieves an invoice with its items, products, and customer details.
  Future<DetailedInvoice> getInvoiceWithDetails(int invoiceId) async {
    final invoice = await (select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
    
    final customer = invoice.customerId != null 
      ? await (select(db.customers)..where((t) => t.id.equals(invoice.customerId!))).getSingleOrNull()
      : null;

    final itemsQuery = select(db.invoiceItems).join([
      innerJoin(db.products, db.products.id.equalsExp(db.invoiceItems.productId)),
      innerJoin(db.batches, db.batches.id.equalsExp(db.invoiceItems.batchId)),
    ]);
    itemsQuery.where(db.invoiceItems.invoiceId.equals(invoiceId));
    
    final itemsRows = await itemsQuery.get();
    final items = itemsRows.map((row) {
      return DetailedInvoiceItem(
        item: row.readTable(db.invoiceItems),
        product: row.readTable(db.products),
        batch: row.readTable(db.batches),
      );
    }).toList();

    final debt = await (select(db.debts)..where((t) => t.invoiceId.equals(invoiceId))).getSingleOrNull();

    return DetailedInvoice(
      invoice: invoice,
      customer: customer,
      items: items,
      debt: debt,
    );
  }

  /// Cancel an invoice: Set status to CANCELED, restore batch quantities, and reverse debts.
  Future<void> cancelInvoice(int invoiceId) {
    return db.transaction(() async {
      final invoice = await (select(db.invoices)..where((t) => t.id.equals(invoiceId))).getSingle();
      if (invoice.status == 'CANCELED') return;

      // Step 1: Restore Stock
      final items = await (select(db.invoiceItems)..where((i) => i.invoiceId.equals(invoiceId))).get();
      for (final item in items) {
        final bTable = db.batches;
        await (update(bTable)..where((t) => t.id.equals(item.batchId)))
            .write(BatchesCompanion.custom(quantity: bTable.quantity + Variable(item.qty)));

        await into(db.stockMovements).insert(StockMovementsCompanion(
          type: const Value('RETURN'),
          productId: Value(item.productId),
          batchId: Value(item.batchId),
          qtyChange: Value(item.qty),
          referenceId: Value(invoiceId),
        ));
      }

      // Step 2: Reverse Debt
      if (invoice.paymentType == 'DEBT' && invoice.customerId != null) {
        final debt = await (select(db.debts)..where((t) => t.invoiceId.equals(invoiceId))).getSingleOrNull();
        if (debt != null) {
          final cTable = db.customers;
          final unpaid = debt.amountTotal - debt.amountPaid;
          await (update(cTable)..where((t) => t.id.equals(invoice.customerId!)))
              .write(CustomersCompanion.custom(totalDebt: cTable.totalDebt - Variable(unpaid)));
          
          // Delete or mark debt as settled
          await (delete(db.debts)..where((t) => t.id.equals(debt.id))).go();
        }
      }

      // Step 3: Mark Invoice as CANCELED
      await (update(db.invoices)..where((i) => i.id.equals(invoiceId)))
          .write(const InvoicesCompanion(status: Value('CANCELED')));
    });
  }
}

class DetailedInvoice {
  final Invoice invoice;
  final Customer? customer;
  final List<DetailedInvoiceItem> items;
  final Debt? debt;
  DetailedInvoice({required this.invoice, this.customer, required this.items, this.debt});
}

class DetailedInvoiceItem {
  final InvoiceItem item;
  final Product product;
  final Batch batch;
  DetailedInvoiceItem({required this.item, required this.product, required this.batch});
}
