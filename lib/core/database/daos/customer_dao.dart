import 'package:drift/drift.dart' hide Batch;
import '../app_database.dart';
import '../tables/tables.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers, Debts])
class CustomerDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  /// Get all customers (for debt selection in POS).
  Future<List<Customer>> getAllCustomers() => select(db.customers).get();

  /// Get a single customer by ID.
  Future<Customer?> getCustomerById(int id) =>
      (select(db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Get total outstanding debt for a customer.
  Future<double> getCustomerDebt(int customerId) async {
    final result = await (select(db.debts)
          ..where((d) => d.customerId.equals(customerId)))
        .get();
    final totalDebt =
        result.fold(0.0, (sum, d) => sum + (d.amountTotal - d.amountPaid));
    return totalDebt;
  }

  /// Record partial payment on a debt.
  Future<void> recordPayment(int debtId, double paymentAmount) {
    return db.transaction(() async {
      final debt = await (select(db.debts)..where((d) => d.id.equals(debtId)))
          .getSingle();
      final newAmountPaid = debt.amountPaid + paymentAmount;
      await (update(db.debts)..where((d) => d.id.equals(debtId)))
          .write(DebtsCompanion(amountPaid: Value(newAmountPaid)));
    });
  }

  /// Add new customer
  Future<int> insertCustomer(CustomersCompanion customer) => 
      into(db.customers).insert(customer);
}


