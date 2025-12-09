import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/expense_category.dart';
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
  Key dropdownKey = UniqueKey();
  String? _editingExpenseId;

  void _clearFields() {
    setState(() {
      description.clear();
      value.clear();
      date = null;
      category = null;
      dropdownKey = UniqueKey();
      _editingExpenseId = null;
    });
  }

  Future<void> _saveExpense() async {
    if (description.text.isEmpty ||
        value.text.isEmpty ||
        date == null ||
        category == null) {
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
      final expenseData = {
        'description': description.text,
        'value': double.parse(value.text.replaceAll(',', '.')),
        'category': category,
        'date': Timestamp.fromDate(date!),
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
    double currentValue,
    String currentCategory,
    DateTime currentDate,
  ) {
    setState(() {
      _editingExpenseId = id;
      description.text = currentDescription;
      value.text = currentValue.toStringAsFixed(2);
      category = currentCategory;
      date = currentDate;
      dropdownKey = UniqueKey();
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
            labelText: 'Valor (R\$)',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
            floatingLabelStyle: TextStyle(color: Colors.green),
          ),
        ),
        SizedBox(height: 16),
        DropdownMenu<String>(
          key: dropdownKey,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Data do gasto:", style: TextStyle(fontSize: 16)),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2026),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.green,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (selectedDate != null) {
                  setState(() {
                    date = selectedDate;
                  });
                }
              },
              icon: Icon(Icons.calendar_today),
              label: Text(
                date == null
                    ? 'Selecionar Data'
                    : '${date!.day}/${date!.month}/${date!.year}',
              ),
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
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
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
            final value = data['value'] is num
                ? (data['value'] as num).toDouble()
                : double.tryParse(data['value'].toString()) ?? 0.0;

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
                                value,
                                data['category'],
                                date,
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
                          '- R\$ ${value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Colors.red[700],
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
