// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_dao.dart';

// ignore_for_file: type=lint
mixin _$InvoiceDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $InvoicesTable get invoices => attachedDatabase.invoices;
  $ProductsTable get products => attachedDatabase.products;
  $BatchesTable get batches => attachedDatabase.batches;
  $InvoiceItemsTable get invoiceItems => attachedDatabase.invoiceItems;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $DebtsTable get debts => attachedDatabase.debts;
  InvoiceDaoManager get managers => InvoiceDaoManager(this);
}

class InvoiceDaoManager {
  final _$InvoiceDaoMixin _db;
  InvoiceDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db.attachedDatabase, _db.invoices);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db.attachedDatabase, _db.batches);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db.attachedDatabase, _db.invoiceItems);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
          _db.attachedDatabase, _db.stockMovements);
  $$DebtsTableTableManager get debts =>
      $$DebtsTableTableManager(_db.attachedDatabase, _db.debts);
}
