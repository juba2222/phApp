import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
