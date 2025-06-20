import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_pos_ac/data/models/expense.dart';
import 'package:app_pos_ac/presentation/features/expenses/viewmodels/expense_viewmodel.dart';
import 'package:app_pos_ac/presentation/common_widgets/app_dialogs.dart';

/// A form view for adding or editing an expense.
class ExpenseInputView extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;

  const ExpenseInputView({super.key, this.expenseToEdit});

  @override
  ConsumerState<ExpenseInputView> createState() => _ExpenseInputViewState();
}

class _ExpenseInputViewState extends ConsumerState<ExpenseInputView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.expenseToEdit?.description ?? '');
    _amountController = TextEditingController(text: widget.expenseToEdit?.amount.toString() ?? '');
    _selectedDate = widget.expenseToEdit?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final description = _descriptionController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final expenseNotifier = ref.read(expenseProvider.notifier);

      try {
        if (widget.expenseToEdit == null) {
          await expenseNotifier.addExpense(description, amount, _selectedDate);
          if (mounted) {
            await showAppMessageDialog(context, title: 'Success', message: 'Expense added successfully!');
          }
        } else {
          await expenseNotifier.updateExpense(
            widget.expenseToEdit!.id!,
            description,
            amount,
            _selectedDate,
          );
          if (mounted) {
            await showAppMessageDialog(context, title: 'Success', message: 'Expense updated successfully!');
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          await showAppMessageDialog(context, title: 'Error', message: e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        title: Text(widget.expenseToEdit == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Description cannot be empty.' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Rp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+\.?[0-9]*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Amount cannot be empty.';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return 'Amount must be a positive number.';
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: dateFormatter.format(_selectedDate)),
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Date cannot be empty.' : null,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(widget.expenseToEdit == null ? Icons.add : Icons.save),
                  label: Text(widget.expenseToEdit == null ? 'Tambah Pengeluaran' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
