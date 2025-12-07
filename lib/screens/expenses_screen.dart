import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/category.dart';
import 'package:flutter/material.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
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
      _editingExpenseId = null;
      dropdownKey = UniqueKey();
    });
  }

  Future<void> _saveExpense() async {
    if (description.text.isEmpty ||
        value.text.isEmpty ||
        date == null ||
        category == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
      } else {
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(_editingExpenseId)
            .update(expenseData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gasto ${_editingExpenseId == null ? 'registrado' : 'atualizado'} com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearFields();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startEdit(
      String id, String currentDescription, double currentValue,
      String currentCategory, DateTime currentDate) {
    setState(() {
      _editingExpenseId = id;
      description.text = currentDescription;
      value.text = currentValue.toString();
      category = currentCategory;
      date = currentDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              _editingExpenseId == null
                  ? "Digite os dados do novo gasto:"
                  : "Editando gasto:",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              key: dropdownKey,
              width: MediaQuery.of(context).size.width - 48,
              label: const Text('Categoria'),
              hintText: 'Escolha uma categoria',
              initialSelection: category,
              enableSearch: false,
              enableFilter: false,
              requestFocusOnTap: false,
              dropdownMenuEntries: Categories.all.map((String cat) {
                return DropdownMenuEntry<String>(value: cat, label: cat);
              }).toList(),
              onSelected: (String? newValue) {
                setState(() {
                  category = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Data do gasto:", style: TextStyle(fontSize: 16)),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2026),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
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
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    date == null
                        ? 'Selecionar Data'
                        : '${date!.day}/${date!.month}/${date!.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _clearFields();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Campos limpos com sucesso!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _saveExpense,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Histórico de Gastos",
              style: TextStyle(fontSize: 24),
            ),
            _buildExpensesList(),
          ],
        ),
      ),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma despesa registrada.'));
        }

        final expenses = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final data = expense.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(data['description']),
                subtitle: Text(data['category']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'R\$ ${data['value'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('${date.day}/${date.month}/${date.year}'),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _startEdit(
                        expense.id,
                        data['description'],
                        data['value'],
                        data['category'],
                        date,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteExpense(expense.id),
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
          const SnackBar(
            content: Text('Gasto excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir gasto: $e'),
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
