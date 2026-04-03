import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/invoice_history_cubit.dart';

class PosHistorySheet extends StatelessWidget {
  final Function(int) onInvoiceTap;

  const PosHistorySheet({super.key, required this.onInvoiceTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'سجل الفواتير الأخيرة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: BlocBuilder<InvoiceHistoryCubit, InvoiceHistoryState>(
              builder: (context, state) {
                if (state is InvoiceHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InvoiceHistoryLoaded) {
                  if (state.recentInvoices.isEmpty) {
                    return const Center(child: Text('لا توجد فواتير بعد'));
                  }
                  return ListView.builder(
                    itemCount: state.recentInvoices.length,
                    itemBuilder: (context, index) {
                      final inv = state.recentInvoices[index];
                      final isCanceled = inv.status == 'CANCELED';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCanceled
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          child: Icon(
                            Icons.receipt_long,
                            color: isCanceled ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text('Invoice #${inv.id}'),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(inv.createdAt),
                        ),
                        trailing: Text(
                          '${inv.totalAmount} د.ع',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onInvoiceTap(inv.id);
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
    );
  }
}
