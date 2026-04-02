import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables/tables.dart';

class DataSeeder {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    print('🌱 Syncing Test Data...');

    // Helper to get or create product
    Future<Product> getOrCreateProduct(String name, String barcode, double sell, double base) async {
      final existing = await (db.select(db.products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
      if (existing != null) return existing;
      return db.into(db.products).insertReturning(ProductsCompanion.insert(name: name, barcode: barcode, sellPrice: sell, basePrice: base));
    }

    // Helper to add batch if product has no batches
    Future<void> addBatchIfMissing(int productId, String batchNum, DateTime expiry, int qty) async {
      final existing = await (db.select(db.batches)..where((b) => b.productId.equals(productId) & b.batchNum.equals(batchNum))).getSingleOrNull();
      if (existing != null) return;
      await db.into(db.batches).insert(BatchesCompanion.insert(productId: productId, batchNum: batchNum, expiryDate: expiry, quantity: qty));
    }


    // 1. ADD PRODUCTS & BATCHES
    
    // PANADOL (12345)
    final p1 = await getOrCreateProduct('بندول Panadol 500mg', '12345', 5000, 3500);
    await addBatchIfMissing(p1.id, 'P-001', DateTime.now().add(const Duration(days: 14)), 15);
    await addBatchIfMissing(p1.id, 'P-002', DateTime.now().add(const Duration(days: 700)), 100);

    // VITAMIN C (11111)
    final p2 = await getOrCreateProduct('فيتامين سي Vitamin C', '11111', 2000, 1000);
    await addBatchIfMissing(p2.id, 'VIT-01', DateTime.now().add(const Duration(days: 2)), 2);
    await addBatchIfMissing(p2.id, 'VIT-02', DateTime.now().add(const Duration(days: 365)), 50);

    // DEXA (33333)
    final p3 = await getOrCreateProduct('ديكساميثازون Dexa', '33333', 25000, 18000);
    await addBatchIfMissing(p3.id, 'D-88', DateTime.now().add(const Duration(days: 400)), 20);

    // OMEPRAZOLE (44444) - No batches (Out of Stock)
    await getOrCreateProduct('اوميبرازول Omeprazole', '44444', 15000, 10000);

    // 2. CUSTOMERS
    final c1 = await (db.select(db.customers)..where((c) => c.name.equals('أحمد علي (صيدلي تجريبي)'))).getSingleOrNull();
    if (c1 == null) {
      await db.into(db.customers).insert(CustomersCompanion.insert(name: 'أحمد علي (صيدلي تجريبي)', phone: const Value('0781234567')));
    }

    print('✅ Test Data Synced.');
  }

}

