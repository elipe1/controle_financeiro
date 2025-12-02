// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro/category.dart';
import 'package:flutter/material.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  State<Expense> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  final TextEditingController description = TextEditingController();
  final TextEditingController value = TextEditingController();
  DateTime? date;
  String? category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar novo gasto'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Digite os dados do novo gasto:",
                style: TextStyle(fontSize: 24),
              ),

              // Description Input
              SizedBox(height: 16),
              TextField(
                controller: description,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
              ),

              // Value Input
              SizedBox(height: 16),
              TextField(
                controller: value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                ),
              ),

              // Category Dropdown
              SizedBox(height: 16),
              DropdownMenu<String>(
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

              // Date Picker
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Data do gasto:", style: TextStyle(fontSize: 16)),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
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
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      date == null
                          ? 'Selecionar Data'
                          : '${date!.day}/${date!.month}/${date!.year}',
                    ),
                  ),
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
