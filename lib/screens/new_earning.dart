import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/earning_category.dart';
import 'package:controle_financeiro/currency.dart';
import 'package:controle_financeiro/services/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Earning extends StatefulWidget {
  Earning({super.key});

  @override
  State<Earning> createState() => _EarningState();
}

class _EarningState extends State<Earning> {
  final TextEditingController description = TextEditingController();
  final TextEditingController value = TextEditingController();
  DateTime? date;
  String? category;
  String? currency;
  Key categorydropdownKey = UniqueKey();
  Key currencyDropdownKey = UniqueKey();
  String? _editingEarningId;
  late final Stream<QuerySnapshot> _earningsStream;

  @override
  void initState() {
    super.initState();
    _earningsStream = FirebaseFirestore.instance
        .collection('earnings')
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
      _editingEarningId = null;
    });
  }

  Future<void> _saveEarning() async {
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

      if (currency != 'BRL') {
        valueToSave = await CurrencyService.convertCurrency(
          currency!,
          'BRL',
          originalValue,
        );
      }

      final earningData = {
        'description': description.text,
        'value': valueToSave,
        'originalValue': originalValue,
        'category': category,
        'date': Timestamp.fromDate(date!),
        'currency': currency,
      };

      if (_editingEarningId == null) {
        await FirebaseFirestore.instance.collection('earnings').add({
          ...earningData,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ganho registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('earnings')
            .doc(_editingEarningId)
            .update({
              ...earningData,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ganho atualizado com sucesso!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) {
        _clearFields();
        setState(() {
          _editingEarningId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ganho: $e'),
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
      _editingEarningId = id;
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
            _buildAddEarningForm(),
            Divider(thickness: 2, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 24),
                children: [
                  TextSpan(text: "Histórico de "),
                  TextSpan(
                    text: "GANHOS:",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildEarningsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEarningForm() {
    return Column(
      children: [
        Text(
          _editingEarningId == null
              ? 'Digite os dados do novo ganho:'
              : 'Edite os dados do ganho:',
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
          dropdownMenuEntries: EarningCategories.all.map((String cat) {
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
            Text("Data do ganho:", style: TextStyle(fontSize: 16)),
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
              onPressed: _saveEarning,
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

  Widget _buildEarningsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _earningsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Nenhum ganho registrado.'));
        }

        final earnings = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: earnings.length,
          itemBuilder: (context, index) {
            final earning = earnings[index];
            final data = earning.data() as Map<String, dynamic>;
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
                                earning.id,
                                data['description'],
                                originalValue,
                                data['category'],
                                date,
                                currency,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEarning(earning.id),
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
                          '+ $currency ${originalValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
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

  Future<void> _deleteEarning(String id) async {
    try {
      await FirebaseFirestore.instance.collection('earnings').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ganho excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir ganho: $e'),
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
