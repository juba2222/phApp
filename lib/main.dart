import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/app_database.dart';
import 'core/database/daos/batch_dao.dart';
import 'core/database/daos/invoice_dao.dart';
import 'core/database/daos/customer_dao.dart';
import 'features/pos/presentation/cubit/sales_cubit.dart';
import 'features/pos/presentation/screens/pos_screen.dart';

import 'core/database/data_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final db = AppDatabase();
  
  // Seed initial values for testing
  await DataSeeder.seedIfEmpty(db);
  
  runApp(PharmaFixApp(db: db));
}

class PharmaFixApp extends StatelessWidget {
  final AppDatabase db;
  const PharmaFixApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PharmaFix POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'OpenSans', // Common arabic-friendly font
      ),
      home: BlocProvider(
        create: (_) => SalesCubit(
          db: db,
          batchDao: BatchDao(db),
          invoiceDao: InvoiceDao(db),
          customerDao: CustomerDao(db),
        ),
        child: const PosScreen(),
      ),
    );
  }
}

