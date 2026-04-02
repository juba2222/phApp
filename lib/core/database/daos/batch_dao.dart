import 'package:drift/drift.dart' hide Batch;
import '../app_database.dart';
import '../tables/tables.dart';

part 'batch_dao.g.dart';

@DriftAccessor(tables: [Batches, Products])
class BatchDao extends DatabaseAccessor<AppDatabase> with _$BatchDaoMixin {
  BatchDao(super.db);

  /// FEFO: Returns all active batches for a product, sorted by expiry (nearest first).
  /// Filters out expired batches and batches with zero quantity.
  Future<List<Batch>> getFefoBatches(int productId) {
    return (select(db.batches)
          ..where((b) => b.productId.equals(productId))
          ..where((b) => b.quantity.isBiggerThanValue(0))
          ..where((b) => b.expiryDate.isBiggerThan(Variable(DateTime.now())))
          ..orderBy([(b) => OrderingTerm(expression: b.expiryDate)]))
        .get();
  }

  /// Decrement batch quantity by a given amount (used inside an atomic transaction).
  Future<int> decrementQuantity(int batchId, int amount) {
    return customUpdate(
      'UPDATE batches SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
      variables: [Variable(amount), Variable(batchId), Variable(amount)],
      updates: {db.batches},
    );
  }

  /// Increment batch quantity (used during RETURN/Rollback).
  Future<int> incrementQuantity(int batchId, int amount) {
    return customUpdate(
      'UPDATE batches SET quantity = quantity + ? WHERE id = ?',
      variables: [Variable(amount), Variable(batchId)],
      updates: {db.batches},
    );
  }
}
