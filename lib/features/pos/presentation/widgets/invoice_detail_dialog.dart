import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/daos/invoice_dao.dart';
import '../cubit/invoice_history_cubit.dart';
import 'package:intl/intl.dart';

class InvoiceDetailDialog extends StatelessWidget {
  final int invoiceId;

  const InvoiceDetailDialog({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<InvoiceHistoryCubit>()..loadInvoiceDetails(invoiceId),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: BlocConsumer<InvoiceHistoryCubit, InvoiceHistoryState>(
            listener: (context, state) {
              if (state is InvoiceCancelSuccess) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء الفاتورة بنجاح')),
                );
              }
              if (state is InvoiceHistoryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (state is InvoiceHistoryLoading) {
                return const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()));
              }

              if (state is InvoiceDetailLoaded) {
                final detailed = state.detailedInvoice;
                final invoice = detailed.invoice;
                final isCanceled = invoice.status == 'CANCELED';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glass Header
                    _buildHeader(invoice, isCanceled),
                    
                    // Customer Info if exists
                    if (detailed.customer != null)
                      _buildCustomerInfo(detailed.customer!),

                    // Items List
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: detailed.items.length,
                          itemBuilder: (context, index) => _buildItemCard(detailed.items[index]),
                        ),
                      ),
                    ),

                    // Totals & Actions
                    _buildFooter(context, detailed, isCanceled),
                  ],
                );
              }
              return const SizedBox(height: 400, child: Center(child: Text('Unexpected State')));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic invoice, bool isCanceled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice #${invoice.id}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(invoice.createdAt),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCanceled ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isCanceled ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5)),
            ),
            child: Text(
              isCanceled ? 'CANCELED' : 'COMPLETED',
              style: TextStyle(
                color: isCanceled ? Colors.red : Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(dynamic customer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          if (customer.phone != null) ...[
            const Spacer(),
            Text(customer.phone!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(DetailedInvoiceItem detail) {
    final diff = detail.item.priceAtSale - detail.item.suggestedPrice;
    final isDiscount = diff < 0;
    final absDiff = diff.abs();
    final percent = (absDiff / detail.item.suggestedPrice * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Qty: ${detail.item.qty}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${detail.item.priceAtSale * detail.item.qty} IQD', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (absDiff > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDiscount ? Colors.red : Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isDiscount ? "-" : " "}$percent%',
                    style: TextStyle(color: isDiscount ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, DetailedInvoice detailed, bool isCanceled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
              Text('${detailed.invoice.totalAmount} IQD', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          if (detailed.debt != null) ...[
            const SizedBox(height: 12),
            _buildFinanceRow('Paid Upfront', '${detailed.debt!.amountPaid} IQD', Colors.greenAccent),
            const SizedBox(height: 4),
            _buildFinanceRow('Remaining Debt', '${detailed.debt!.amountTotal - detailed.debt!.amountPaid} IQD', Colors.orangeAccent),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Method', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text(detailed.invoice.paymentType, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          if (!isCanceled)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmCancellation(context),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: const Text('إلغاء الفاتورة', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('إغلاق', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('رجوع', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _confirmCancellation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد من إلغاء هذه الفاتورة؟ سيتم إعادة المنتجات للمخزون وعكس المبالغ المالية.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<InvoiceHistoryCubit>().cancelInvoice(invoiceId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، قم بالإلغاء'),
          ),
        ],
      ),
    );
  }
}
