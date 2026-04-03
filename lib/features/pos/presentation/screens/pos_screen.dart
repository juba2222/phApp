import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/invoice_history_cubit.dart';
import '../widgets/invoice_detail_dialog.dart';
import '../widgets/pos_scanner_dialog.dart';
import '../widgets/search_input_section.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/checkout_bar.dart';
import '../widgets/pos_history_sheet.dart';
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchFocus.requestFocus());
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
        title: const Text('نقطة البيع',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'السجل',
            onPressed: () => _openHistorySheet(context),
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
          SearchInputSection(
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
              listener: _onSalesStateChange,
              builder: (context, state) {
                if (state is SalesScanning) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SalesCommitting) {
                  return const _CommittingView();
                }

                final items = state is SalesActive
                    ? state.items
                    : state is SalesPaymentPending
                        ? state.items
                        : <CartItem>[];

                if (items.isEmpty) {
                  return _EmptyCartView(
                    onScanPressed: () => _openScanner(context),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      CartItemTile(item: items[index]),
                );
              },
            ),
          ),
          const CheckoutBar(),
        ],
      ),
    );
  }

  void _onSalesStateChange(BuildContext context, SalesState state) {
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

  void _openHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<InvoiceHistoryCubit>()..loadRecentInvoices(),
        child: PosHistorySheet(
          onInvoiceTap: (id) => _showInvoiceDetails(context, id),
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  final VoidCallback onScanPressed;
  const _EmptyCartView({required this.onScanPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 80, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          const Text('امسح باركود المنتج للبدء',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onScanPressed,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('فتح الماسح الضوئي'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F5E9),
              foregroundColor: const Color(0xFF00C853),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommittingView extends StatelessWidget {
  const _CommittingView();

  @override
  Widget build(BuildContext context) {
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
}
