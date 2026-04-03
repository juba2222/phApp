part of sales_cubit;

// Represents a single item in the active invoice draft (may span multiple batches)
class CartItem {
  final int productId;
  final String productName;
  final int batchId;
  final DateTime expiryDate;
  final int qty;
  final double priceAtSale;
  final double suggestedPrice; // Store original DB price for discount/premium calculation

  const CartItem({
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.expiryDate,
    required this.qty,
    required this.priceAtSale,
    required this.suggestedPrice,
  });

  double get subtotal => qty * priceAtSale;
  
  // Calculate discount/premium percentage
  double get adjustmentPercentage {
    if (suggestedPrice == 0) return 0;
    return ((priceAtSale - suggestedPrice) / suggestedPrice) * 100;
  }
}

abstract class SalesState {}

/// No active sale
class SalesInitial extends SalesState {}

/// Scanning/Looking up a barcode
class SalesScanning extends SalesState {}

/// Items added in cart
class SalesActive extends SalesState {
  final List<CartItem> items;
  final double total;
  SalesActive({required this.items, required this.total});
}

/// Waiting for payment confirmation
class SalesPaymentPending extends SalesState {
  final List<CartItem> items;
  final double total;
  final String? paymentType; // 'CASH', 'BANK', 'DEBT'
  final int? customerId;
  SalesPaymentPending({
    required this.items,
    required this.total,
    this.paymentType,
    this.customerId,
  });
}

/// Executing atomic DB transaction
class SalesCommitting extends SalesState {}

/// Sale completed successfully
class SalesSuccess extends SalesState {
  final int invoiceId;
  SalesSuccess({required this.invoiceId});
}

/// Sale failed + Rollback triggered
class SalesError extends SalesState {
  final String message;
  SalesError({required this.message});
}
