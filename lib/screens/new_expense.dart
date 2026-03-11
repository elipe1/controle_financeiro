import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/expense_category.dart';
import 'package:controle_financeiro/currency.dart';
import 'package:controle_financeiro/services/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Expense extends StatefulWidget {
  Expense({super.key});

  @override
  State<Expense> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  final TextEditingController description = TextEditingController();
  final TextEditingController value = TextEditingController();
  DateTime? date;
  String? category;
  String? currency;
  Key categorydropdownKey = UniqueKey();
  Key currencyDropdownKey = UniqueKey();
  String? _editingExpenseId;
  late final Stream<QuerySnapshot> _expensesStream;

  @override
  void initState() {
    super.initState();
    _expensesStream = FirebaseFirestore.instance
        .collection('expenses')
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();
  }

  void _clearFields() {
    setState(() {
      description.clear();
      value.clear();
      date = null;
      category = null;
      currency = null;
      categorydropdownKey = UniqueKey();
      currencyDropdownKey = UniqueKey();
      _editingExpenseId = null;
    });
  }

  Future<void> _saveExpense() async {
    if (description.text.isEmpty ||
        value.text.isEmpty ||
        date == null ||
        category == null ||
        currency == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, preencha todos os campos.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final originalValue = double.parse(value.text.replaceAll(',', '.'));
      double valueToSave = originalValue;
      final currencyCode = currency!.split(' ').first;

      if (currencyCode != 'BRL') {
        valueToSave = await CurrencyService.convertCurrency(
          currencyCode,
          'BRL',
          originalValue,
        );
      }

      final expenseData = {
        'description': description.text,
        'value': valueToSave,
        'originalValue': originalValue,
        'category': category,
        'date': Timestamp.fromDate(date!),
        'currency': currency,
      };

      if (_editingExpenseId == null) {
        await FirebaseFirestore.instance.collection('expenses').add({
          ...expenseData,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gasto registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(_editingExpenseId)
            .update({
              ...expenseData,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gasto atualizado com sucesso!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) {
        _clearFields();
        setState(() {
          _editingExpenseId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startEdit(
    String id,
    String currentDescription,
    double originalValue,
    String currentCategory,
    DateTime currentDate,
    String currentCurrency,
  ) {
    setState(() {
      _editingExpenseId = id;
      description.text = currentDescription;
      value.text = originalValue.toStringAsFixed(2);
      category = currentCategory;
      date = currentDate;
      currency = currentCurrency;
      categorydropdownKey = UniqueKey();
      currencyDropdownKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildAddExpenseForm(),
            Divider(thickness: 2, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 24),
                children: [
                  TextSpan(text: "Histórico de "),
                  TextSpan(
                    text: "GASTOS:",
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildExpensesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExpenseForm() {
    return Column(
      children: [
        Text(
          _editingExpenseId == null
              ? 'Digite os dados do novo gasto:'
              : 'Edite os dados do gasto:',
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 16),
        TextField(
          controller: description,
          decoration: InputDecoration(
            labelText: 'Descrição',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
            floatingLabelStyle: TextStyle(color: Colors.green),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: value,
          keyboardType: TextInputType.numberWithOptions(
            decimal: true,
            signed: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Valor',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
            floatingLabelStyle: TextStyle(color: Colors.green),
          ),
        ),
        SizedBox(height: 16),
        DropdownMenu<String>(
          key: currencyDropdownKey,
          width: MediaQuery.of(context).size.width - 48,
          label: Text('Moeda'),
          hintText: 'Escolha uma moeda',
          initialSelection: currency,
          enableSearch: false,
          enableFilter: false,
          requestFocusOnTap: false,
          dropdownMenuEntries: Currency.all.map((String c) {
            return DropdownMenuEntry<String>(value: c, label: c);
          }).toList(),
          onSelected: (String? newValue) {
            setState(() {
              currency = newValue;
            });
          },
        ),
        SizedBox(height: 16),
        DropdownMenu<String>(
          key: categorydropdownKey,
          width: MediaQuery.of(context).size.width - 48,
          label: Text('Categoria'),
          hintText: 'Escolha uma categoria',
          initialSelection: category,
          enableSearch: false,
          enableFilter: false,
          requestFocusOnTap: false,
          dropdownMenuEntries: ExpenseCategory.all.map((String cat) {
            return DropdownMenuEntry<String>(value: cat, label: cat);
          }).toList(),
          onSelected: (String? newValue) {
            setState(() {
              category = newValue;
            });
          },
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled:
                    !(date != null &&
                        date!.year == DateTime.now().year &&
                        date!.month == DateTime.now().month &&
                        date!.day == DateTime.now().day),
                controller: TextEditingController(
                  text: date == null
                      ? ''
                      : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}',
                ),
                decoration: InputDecoration(
                  labelText: 'Data (dd/mm/yyyy)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  floatingLabelStyle: TextStyle(color: Colors.green),
                ),
                inputFormatters: [_DateInputFormatter()],
                onChanged: (value) {
                  if (value.length == 10) {
                    try {
                      final parts = value.split('/');
                      final day = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final year = int.parse(parts[2]);

                      if (month < 1 || month > 12) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Mês inválido. Use um valor entre 01 e 12.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (day < 1 || day > DateTime(year, month + 1, 0).day) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dia inválido para o mês informado.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (year > DateTime.now().year) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'O ano não pode ser maior que ${DateTime.now().year}.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final parsedDate = DateTime(year, month, day);
                      if (parsedDate.isAfter(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('A data não pode ser futura.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        date = parsedDate;
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data inválida.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            SizedBox(width: 25),
            Text("Hoje?", style: TextStyle(fontSize: 14)),
            Checkbox(
              activeColor: Colors.green,
              value:
                  date != null &&
                  date!.year == DateTime.now().year &&
                  date!.month == DateTime.now().month &&
                  date!.day == DateTime.now().day,
              onChanged: (value) {
                final now = DateTime.now();
                setState(() {
                  date = value == true
                      ? DateTime(now.year, now.month, now.day)
                      : null;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                if (mounted) {
                  if (date == null &&
                      category == null &&
                      description.text.isEmpty &&
                      value.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nenhum campo para limpar.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    _clearFields();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Campos limpos com sucesso!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                }
              },
              icon: Icon(Icons.clear),
              label: Text('Limpar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _saveExpense,
              icon: Icon(Icons.save),
              label: Text('Salvar'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
        SizedBox(height: 32),
      ],
    );
  }

  Widget _buildExpensesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Nenhuma despesa registrada.'));
        }

        final expenses = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final data = expense.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final originalValue = data.containsKey('originalValue')
                ? (data['originalValue'] as num).toDouble()
                : (data['value'] as num).toDouble();
            final currency = data['currency'] ?? 'BRL';

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['description'].toString().toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEdit(
                                expense.id,
                                data['description'],
                                originalValue,
                                data['category'],
                                date,
                                currency,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExpense(expense.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(data['category']),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text('${date.day}/${date.month}/${date.year}'),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '- ${currency.split(' ').first} ${originalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Despesa excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir despesa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    description.dispose();
    value.dispose();
    super.dispose();
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 8) return oldValue;
    if (!RegExp(r'^\d*$').hasMatch(text)) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
