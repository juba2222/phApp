import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/app_database.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  String _selectedType = 'CASH';
  int? _selectedCustomerId;
  List<Customer> _customers = [];
  
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
    _downPaymentController.dispose();
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
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
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
              child: const Text('تأكيد وإصدار الفاتورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCustomerId,
                hint: const Text('اختر العميل...'),
                isExpanded: true,
                items: _customers.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCustomerId = val),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => setState(() => _isAddingCustomer = true),
          icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF00C853)),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.add_circle, color: Color(0xFF00C853), size: 20),
              SizedBox(width: 8),
              Text('إضافة عميل جديد', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'اسم العميل*', isDense: true),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'رقم الهاتف (اختياري)', isDense: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: () => setState(() => _isAddingCustomer = false), child: const Text('إلغاء')),
              const Spacer(),
              ElevatedButton(onPressed: _handleQuickAdd, child: const Text('حفظ واختيار')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final color = isSelected ? const Color(0xFF00C853) : Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade200, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
