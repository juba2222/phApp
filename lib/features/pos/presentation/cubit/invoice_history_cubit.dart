import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/invoice_dao.dart';

part 'invoice_history_state.dart';

class InvoiceHistoryCubit extends Cubit<InvoiceHistoryState> {
  final InvoiceDao _invoiceDao;
  final AppDatabase _db;

  InvoiceHistoryCubit({
    required InvoiceDao invoiceDao,
    required AppDatabase db,
  })  : _invoiceDao = invoiceDao,
        _db = db,
        super(InvoiceHistoryInitial());

  Future<void> loadRecentInvoices() async {
    emit(InvoiceHistoryLoading());
    try {
      final invoices = await (_db.select(_db.invoices)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(20))
          .get();
      emit(InvoiceHistoryLoaded(recentInvoices: invoices));
    } catch (e) {
      emit(InvoiceHistoryError(message: 'فشل تحميل الفواتير: $e'));
    }
  }

  Future<void> loadInvoiceDetails(int id) async {
    emit(InvoiceHistoryLoading());
    try {
      final detailed = await _invoiceDao.getInvoiceWithDetails(id);
      emit(InvoiceDetailLoaded(detailedInvoice: detailed));
    } catch (e) {
      emit(InvoiceHistoryError(message: 'فشل تحميل تفاصيل الفاتورة: $id - $e'));
    }
  }

  Future<void> cancelInvoice(int id) async {
    emit(InvoiceHistoryLoading());
    try {
      await _invoiceDao.cancelInvoice(id);
      emit(InvoiceCancelSuccess(invoiceId: id));
      // Refresh list
      loadRecentInvoices();
    } catch (e) {
      emit(InvoiceHistoryError(message: 'فشل إلغاء الفاتورة: $e'));
    }
  }
}
