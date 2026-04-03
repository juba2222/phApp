import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/invoice_history_cubit.dart';
import '../widgets/invoice_detail_dialog.dart';
import '../widgets/pos_scanner_dialog.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/invoice_dao.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => InvoiceHistoryCubit(
            db: context.read<AppDatabase>(),
            invoiceDao: context.read<InvoiceDao>(),
          ),
        ),
      ],
      child: const _PosScreenInternal(),
    );
  }
}

class _PosScreenInternal extends StatefulWidget {
  const _PosScreenInternal();

  @override
  State<_PosScreenInternal> createState() => _PosScreenInternalState();
}

class _PosScreenInternalState extends State<_PosScreenInternal> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Product> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    final results = await context.read<SalesCubit>().searchProducts(query);
    if (mounted) setState(() => _searchResults = results);
  }

  void _onProductSelected(Product product) {
    context.read<SalesCubit>().addProductById(product.id, 1);
    _searchController.clear();
    setState(() => _searchResults = []);
    _searchFocus.requestFocus();
  }

  void _onSearchSubmit() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.read<SalesCubit>().addProductByBarcode(query, 1);
    _searchController.clear();
    setState(() => _searchResults = []);
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C853),
        foregroundColor: Colors.white,
        title: const Text('نقطة البيع', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'السجل',
            onPressed: () => _showHistoryBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'بيع جديد',
            onPressed: () => context.read<SalesCubit>().resetSale(),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchInputSection(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            onSubmit: _onSearchSubmit,
            results: _searchResults,
            onProductSelected: _onProductSelected,
            onScanPressed: () => _openScanner(context),
          ),
          Expanded(
            child: BlocConsumer<SalesCubit, SalesState>(
              listener: (context, state) {
                if (state is SalesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.read<SalesCubit>().resetSale();
                }
                if (state is SalesSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ تمت عملية البيع بنجاح'),
                      backgroundColor: const Color(0xFF00C853),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'عرض الفاتورة',
                        textColor: Colors.white,
                        onPressed: () => _showInvoiceDetails(context, state.invoiceId),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is SalesScanning) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SalesCommitting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00C853)),
                        SizedBox(height: 16),
                        Text('جاري حفظ الفاتورة...'),
                      ],
                    ),
                  );
                }
                
                final items = state is SalesActive ? state.items
                    : state is SalesPaymentPending ? state.items
                    : <CartItem>[];
                
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Color(0xFFBDBDBD)),
                        SizedBox(height: 12),
                        Text('امسح باركود المنتج للبدء',
                            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
                        SizedBox(height: 16),
                        _ScannerShortcutButton(),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _CartItemTile(item: items[index]),
                );
              },
            ),
          ),
          const _CheckoutBar(),
        ],
      ),
    );
  }

  void _openScanner(BuildContext context) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const PosScannerDialog(),
    );
    if (code != null && context.mounted) {
      context.read<SalesCubit>().addProductByBarcode(code, 1);
    }
  }

  void _showInvoiceDetails(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<InvoiceHistoryCubit>(),
        child: InvoiceDetailDialog(invoiceId: id),
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<InvoiceHistoryCubit>()..loadRecentInvoices(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('سجل الفواتير الأخيرة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: BlocBuilder<InvoiceHistoryCubit, InvoiceHistoryState>(
                  builder: (context, state) {
                    if (state is InvoiceHistoryLoading) return const Center(child: CircularProgressIndicator());
                    if (state is InvoiceHistoryLoaded) {
                      if (state.recentInvoices.isEmpty) return const Center(child: Text('لا توجد فواتير بعد'));
                      return ListView.builder(
                        itemCount: state.recentInvoices.length,
                        itemBuilder: (context, index) {
                          final inv = state.recentInvoices[index];
                          final isCanceled = inv.status == 'CANCELED';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCanceled ? Colors.red.shade50 : Colors.green.shade50,
                              child: Icon(Icons.receipt_long, color: isCanceled ? Colors.red : Colors.green),
                            ),
                            title: Text('Invoice #${inv.id}'),
                            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(inv.createdAt)),
                            trailing: Text('${inv.totalAmount} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.pop(context);
                              _showInvoiceDetails(context, inv.id);
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Barcode Input Section
// ───────────────────────────────────────────────
class _SearchInputSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final VoidCallback onSubmit;
  final List<Product> results;
  final Function(Product) onProductSelected;
  final VoidCallback onScanPressed;

  const _SearchInputSection({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.results,
    required this.onProductSelected,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF00C853), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الباركود...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F4F0),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF00C853)),
                      onPressed: onScanPressed,
                    ),
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                child: const Icon(Icons.add_shopping_cart),
              ),
            ],
          ),
        ),
        if (results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = results[index];
                return ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.barcode, style: const TextStyle(fontSize: 12)),
                  trailing: Text('${p.sellPrice.toStringAsFixed(2)} د.ع',
                      style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
                  onTap: () => onProductSelected(p),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────────────────────────
// Cart Item Tile
// ───────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpiringSoon = item.expiryDate.difference(DateTime.now()).inDays <= 30;
    final adj = item.adjustmentPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication, color: Color(0xFF00C853)),
                ),
                const SizedBox(width: 12),
                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'ينتهي: ${item.expiryDate.month}/${item.expiryDate.year}',
                            style: TextStyle(
                              color: isExpiringSoon ? Colors.orange : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => context.read<SalesCubit>().removeItem(item.batchId),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Qty Selector
                Row(
                  children: [
                    _QtyBtn(icon: Icons.remove, onTap: () => context.read<SalesCubit>().updateItemQty(item.batchId, -1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _QtyBtn(icon: Icons.add, onTap: () => context.read<SalesCubit>().updateItemQty(item.batchId, 1)),
                  ],
                ),
                // Price & Adjustment
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (adj != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: adj > 0 ? Colors.red.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${adj > 0 ? "+" : ""}${adj.toStringAsFixed(1)}%',
                              style: TextStyle(color: adj > 0 ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _editPrice(context),
                          child: Text(
                            '${item.priceAtSale.toStringAsFixed(2)} د.ع',
                            style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'المجموع: ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPrice(BuildContext context) {
    final controller = TextEditingController(text: item.priceAtSale.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل السعر'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'السعر المقترح: ${item.suggestedPrice}',
            suffixText: 'د.ع',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                context.read<SalesCubit>().updateItemPrice(item.batchId, newPrice);
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Checkout Bar (Total + Confirm Button)
// ───────────────────────────────────────────────
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesCubit, SalesState>(
      builder: (context, state) {
        final isActive = state is SalesActive || state is SalesPaymentPending;
        final total = state is SalesActive
            ? state.total
            : state is SalesPaymentPending
                ? state.total
                : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08),
                  blurRadius: 12, offset: const Offset(0, -4))
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الإجمالي', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${total.toStringAsFixed(2)} د.ع',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C853)),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: isActive
                    ? () => _showPaymentDialog(context)
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('إتمام البيع', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Required for custom rounded corners
      builder: (_) => BlocProvider.value(
        value: context.read<SalesCubit>(),
        child: const _PaymentSheet(),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Payment Bottom Sheet
// ───────────────────────────────────────────────
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet();

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  String _selectedType = 'CASH';
  int? _selectedCustomerId;
  List<Customer> _customers = [];
  
  // Inline Form State
  bool _isAddingCustomer = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _downPaymentController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final list = await context.read<SalesCubit>().getCustomers();
    if (mounted) setState(() => _customers = list);
  }

  Future<void> _handleQuickAdd() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    final newId = await context.read<SalesCubit>().createCustomer(
      name: name,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );
    
    await _loadCustomers();
    if (mounted) {
      setState(() {
        _selectedCustomerId = newId;
        _isAddingCustomer = false;
        _nameController.clear();
        _phoneController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = context.select((SalesCubit c) => 
        (c.state is SalesActive) ? (c.state as SalesActive).total 
        : (c.state is SalesPaymentPending) ? (c.state as SalesPaymentPending).total : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle for Bottom Sheet
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // Header: Bill Total (Stitch Specification)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الفاتورة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text(
                  '${total.toStringAsFixed(2)} د.ع',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF00C853)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text('طريقة الدفع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentOption(label: 'نقدي', icon: Icons.payments_outlined, value: 'CASH',
                    selected: _selectedType, onTap: () => setState(() => _selectedType = 'CASH')),
                const SizedBox(width: 8),
                _PaymentOption(label: 'بنكي', icon: Icons.account_balance_outlined, value: 'BANK',
                    selected: _selectedType, onTap: () => setState(() => _selectedType = 'BANK')),
                const SizedBox(width: 8),
                _PaymentOption(label: 'دين', icon: Icons.person_outline_rounded, value: 'DEBT',
                    selected: _selectedType, onTap: () => setState(() => _selectedType = 'DEBT')),
              ],
            ),
            
            // Dynamic Section: Debt Management
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _selectedType == 'DEBT' 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      AnimatedCrossFade(
                        firstChild: _buildCustomerSelector(),
                        secondChild: _buildQuickAddForm(),
                        crossFadeState: _isAddingCustomer ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 16),
                      const Text('دفعة نقدية (اختياري)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _downPaymentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'أدخل المبلغ المدفوع حالياً...',
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.payments, color: Color(0xFF00C853)),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            ),

            const SizedBox(height: 40),
            
            // Action Bar: Commit Sale
            ElevatedButton(
              onPressed: (_selectedType == 'DEBT' && _selectedCustomerId == null) ? null : () {
                final downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
                Navigator.pop(context);
                context.read<SalesCubit>().confirmSale(
                  paymentType: _selectedType,
                  customerId: _selectedCustomerId,
                  downPayment: downPayment,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('تأكيد عملية البيع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('اختيار العميل', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _isAddingCustomer = true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('عميل جديد'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00C853)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedCustomerId,
              hint: const Text('ابحث عن اسم العميل...'),
              items: _customers.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                value: c.id,
                child: Text(c.name, style: const TextStyle(fontSize: 15)),
              )).toList(),
              onChanged: (val) => setState(() => _selectedCustomerId = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1, color: Color(0xFF00C853), size: 20),
              const SizedBox(width: 8),
              const Text('إضافة سريعة للعميل', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _isAddingCustomer = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'اسم العميل الكامل',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'رقم الهاتف (اختياري)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleQuickAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('حفظ واختيار'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label, value, selected;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label, required this.icon,
    required this.value, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00C853) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerShortcutButton extends StatelessWidget {
  const _ScannerShortcutButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        final state = context.findAncestorStateOfType<_PosScreenInternalState>();
        if (state != null) {
          state._openScanner(context);
        }
      },
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('فتح الكاميرا للمسح'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

