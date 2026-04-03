import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';
import 'payment_sheet.dart';

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({super.key});

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
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SalesCubit>(),
        child: const PaymentSheet(),
      ),
    );
  }
}
