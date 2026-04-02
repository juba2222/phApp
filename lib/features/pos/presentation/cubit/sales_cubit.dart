import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' hide Batch;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/batch_dao.dart';
import '../../../../core/database/daos/invoice_dao.dart';
import '../../../../core/database/daos/customer_dao.dart';

part 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final AppDatabase _db;
  final BatchDao _batchDao;
  final InvoiceDao _invoiceDao;
  final CustomerDao _customerDao;
 
  final List<CartItem> _cart = [];
 
  SalesCubit({
    required AppDatabase db,
    required BatchDao batchDao,
    required InvoiceDao invoiceDao,
    required CustomerDao customerDao,
  })  : _db = db,
        _batchDao = batchDao,
        _invoiceDao = invoiceDao,
        _customerDao = customerDao,
        super(SalesInitial());
 
  // Search products by name (contains) or barcode (starts with)
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return (_db.select(_db.products)
          ..where((p) => p.name.contains(lowerQuery) | p.barcode.like('$query%')))
        .get();
  }

  // Get customers for debt selection
  Future<List<Customer>> getCustomers() => _customerDao.getAllCustomers();

  // Create new customer on the fly
  Future<int> createCustomer({required String name, String? phone}) =>
      _customerDao.insertCustomer(CustomersCompanion.insert(
        name: name,
        phone: Value(phone),
      ));

  Future<void> addProductById(int productId, int requestedQty) async {
    final product = await (_db.select(_db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingleOrNull();
    if (product != null) await _addWithFefo(product, requestedQty);
  }

  Future<void> addProductByBarcode(String barcode, int requestedQty) async {
    emit(SalesScanning());
    final product = await (_db.select(_db.products)
          ..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();

    if (product == null) {
      emit(SalesError(message: 'المنتج غير موجود: $barcode'));
      return;
    }
    await _addWithFefo(product, requestedQty);
  }

  Future<void> _addWithFefo(Product product, int requestedQty) async {
    try {
      final batches = await _batchDao.getFefoBatches(product.id);
      if (batches.isEmpty) {
        emit(SalesError(message: '${product.name}: لا يوجد مخزون متاح'));
        return;
      }

      final allocated = _allocateFefo(batches, requestedQty, product);
      if (allocated == null) {
        final totalAvailable = batches.fold<int>(0, (int s, Batch b) => s + b.quantity);
        emit(SalesError(
            message: '${product.name}: الكمية المطلوبة ($requestedQty) أكبر من المتاح ($totalAvailable)'));
        return;
      }

      // Add or Merge into cart
      for (var newItem in allocated) {
        final existingIdx = _cart.indexWhere((i) => i.batchId == newItem.batchId);
        if (existingIdx != -1) {
          final existing = _cart[existingIdx];
          _cart[existingIdx] = CartItem(
            productId: existing.productId,
            productName: existing.productName,
            batchId: existing.batchId,
            expiryDate: existing.expiryDate,
            qty: existing.qty + newItem.qty,
            priceAtSale: existing.priceAtSale,
            suggestedPrice: existing.suggestedPrice,
          );
        } else {
          _cart.add(newItem);
        }
      }
      _emitActiveState();
    } catch (e) {
      emit(SalesError(message: 'خطأ: $e'));
    }
  }

  List<CartItem>? _allocateFefo(
      List<Batch> batches, int requestedQty, Product product) {
    final result = <CartItem>[];
    int remaining = requestedQty;

    for (final batch in batches) {
      if (remaining <= 0) break;
      final int take = (batch.quantity >= remaining) ? remaining : batch.quantity;
      result.add(CartItem(
        productId: product.id,
        productName: product.name,
        batchId: batch.id,
        expiryDate: batch.expiryDate,
        qty: take,
        priceAtSale: product.sellPrice,
        suggestedPrice: product.sellPrice,
      ));
      remaining -= take;
    }
    return remaining > 0 ? null : result;
  }

  // ─────────────────────────────────
  // STEP 2: Remove item from cart
  // ─────────────────────────────────
  void updateItemQty(int batchId, int delta) {
    final idx = _cart.indexWhere((i) => i.batchId == batchId);
    if (idx != -1) {
      final item = _cart[idx];
      final newQty = item.qty + delta;
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx] = CartItem(
          productId: item.productId,
          productName: item.productName,
          batchId: item.batchId,
          expiryDate: item.expiryDate,
          qty: newQty,
          priceAtSale: item.priceAtSale,
          suggestedPrice: item.suggestedPrice,
        );
      }
      _emitActiveState();
    }
  }

  void updateItemPrice(int batchId, double newPrice) {
    final idx = _cart.indexWhere((i) => i.batchId == batchId);
    if (idx != -1) {
      final item = _cart[idx];
      _cart[idx] = CartItem(
        productId: item.productId,
        productName: item.productName,
        batchId: item.batchId,
        expiryDate: item.expiryDate,
        qty: item.qty,
        priceAtSale: newPrice,
        suggestedPrice: item.suggestedPrice,
      );
      _emitActiveState();
    }
  }

  void removeItem(int batchId) {
    _cart.removeWhere((item) => item.batchId == batchId);
    _emitActiveState();
  }

  // ─────────────────────────────────────────────
  // STEP 3: Proceed to payment selection
  // ─────────────────────────────────────────────
  void proceedToPayment() {
    emit(SalesPaymentPending(
      items: List.from(_cart),
      total: _calcTotal(),
    ));
  }

  void selectPaymentType(String type, {int? customerId}) {
    emit(SalesPaymentPending(
      items: List.from(_cart),
      total: _calcTotal(),
      paymentType: type,
      customerId: customerId,
    ));
  }

  // ─────────────────────────────────────────────
  // STEP 4: Confirm & Execute Atomic Transaction
  // ─────────────────────────────────────────────
  Future<void> confirmSale({
    required String paymentType,
    int? customerId,
    double downPayment = 0.0,
  }) async {
    if (paymentType == 'DEBT' && customerId == null) {
      emit(SalesError(message: 'يجب اختيار عميل عند البيع بالدين'));
      return;
    }

    emit(SalesCommitting());

    try {
      final total = _calcTotal();
      final invoiceData = InvoicesCompanion(
        customerId: Value(customerId),
        totalAmount: Value(total),
        paymentType: Value(paymentType),
        status: const Value('COMPLETED'),
      );

      final itemsData = _cart
          .map((item) => InvoiceItemsCompanion(
                productId: Value(item.productId),
                batchId: Value(item.batchId),
                qty: Value(item.qty),
                priceAtSale: Value(item.priceAtSale),
                suggestedPrice: Value(item.suggestedPrice),
              ))
          .toList();

      final batchUpdates = _cart
          .map((item) => BatchesCompanion(
                id: Value(item.batchId),
                quantity: Value(-item.qty),
              ))
          .toList();

      // Debt handling
      DebtsCompanion? debtData;
      if (paymentType == 'DEBT') {
        debtData = DebtsCompanion(
          customerId: Value(customerId!),
          amountTotal: Value(total),
          amountPaid: Value(downPayment),
        );
      }

      final invoiceId = await _invoiceDao.executeAtomicSale(
        invoiceData: invoiceData,
        items: itemsData,
        batchUpdates: batchUpdates,
        debtData: debtData,
      );

      _cart.clear();
      emit(SalesSuccess(invoiceId: invoiceId));
    } catch (e) {
      emit(SalesError(message: 'فشل الحفظ: $e'));
    }
  }

  // ─────────────────────────────────
  // STEP 5: Reset to new sale
  // ─────────────────────────────────
  void resetSale() {
    _cart.clear();
    emit(SalesInitial());
  }

  // ─────────────────
  // Helpers
  // ─────────────────
  double _calcTotal() =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  void _emitActiveState() {
    emit(SalesActive(items: List.from(_cart), total: _calcTotal()));
  }
}
