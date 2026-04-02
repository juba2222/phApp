import 'package:drift/drift.dart';

// Product Table
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().unique()();
  RealColumn get sellPrice => real()();
  RealColumn get basePrice => real()();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
}

// Batch Table (Expiry-Aware)
@DataClassName('Batch')
class Batches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get batchNum => text()();
  DateTimeColumn get expiryDate => dateTime()();
  IntColumn get quantity => integer().check(quantity.isBiggerOrEqualValue(0))();
}

// Customer Table
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get totalDebt => real().withDefault(const Constant(0.0))();
}

// Invoice Table
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId =>
      integer().nullable().references(Customers, #id)();
  RealColumn get totalAmount => real()();
  TextColumn get paymentType =>
      text()(); // 'CASH', 'BANK', 'DEBT'
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))(); // PENDING, COMPLETED, CANCELED
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// InvoiceItem (Supports Multi-Batch FEFO Split)
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get batchId => integer().references(Batches, #id)();
  IntColumn get qty => integer()();
  RealColumn get priceAtSale => real()(); // Historical price snapshot
}

// Stock Movement (Full Audit Trail)
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type =>
      text()(); // 'SALE', 'PURCHASE', 'RETURN', 'ADJUSTMENT'
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get batchId => integer().references(Batches, #id)();
  IntColumn get qtyChange => integer()(); // Positive or Negative
  IntColumn get referenceId => integer()(); // Invoice or Purchase ID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Debt Table (Partial Payment Support)
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  RealColumn get amountTotal => real()();
  RealColumn get amountPaid =>
      real().withDefault(const Constant(0.0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
}
