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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: db),
        RepositoryProvider<InvoiceDao>(create: (context) => InvoiceDao(db)),
        RepositoryProvider<BatchDao>(create: (context) => BatchDao(db)),
        RepositoryProvider<CustomerDao>(create: (context) => CustomerDao(db)),
      ],
      child: MaterialApp(
        title: 'PharmaFix POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00C853),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'OpenSans',
        ),
        home: BlocProvider(
          create: (context) => SalesCubit(
            db: context.read<AppDatabase>(),
            batchDao: context.read<BatchDao>(),
            invoiceDao: context.read<InvoiceDao>(),
            customerDao: context.read<CustomerDao>(),
          ),
          child: const PosScreen(),
        ),
      ),
    );
  }
}

