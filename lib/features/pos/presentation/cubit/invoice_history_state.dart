part of 'invoice_history_cubit.dart';

abstract class InvoiceHistoryState {}

class InvoiceHistoryInitial extends InvoiceHistoryState {}

class InvoiceHistoryLoading extends InvoiceHistoryState {}

class InvoiceHistoryLoaded extends InvoiceHistoryState {
  final List<Invoice> recentInvoices;
  InvoiceHistoryLoaded({required this.recentInvoices});
}

class InvoiceDetailLoaded extends InvoiceHistoryState {
  final DetailedInvoice detailedInvoice;
  InvoiceDetailLoaded({required this.detailedInvoice});
}

class InvoiceHistoryError extends InvoiceHistoryState {
  final String message;
  InvoiceHistoryError({required this.message});
}

class InvoiceCancelSuccess extends InvoiceHistoryState {
  final int invoiceId;
  InvoiceCancelSuccess({required this.invoiceId});
}
