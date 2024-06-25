import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uangkoo/models/database.dart';
import 'package:uangkoo/models/transaction.dart';
import 'package:uangkoo/models/transaction_with_category.dart';

class TransactionPage extends StatefulWidget {
  final TransactionWithCategory? transactionsWithCategory;

  const TransactionPage({Key? key, required this.transactionsWithCategory})
      : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  bool isExpense = true;
  late int type;
  final AppDb database = AppDb();
  Category? selectedCategory;
  TextEditingController dateController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Future insert(
      String description, int categoryId, int amount, DateTime date) async {
    DateTime now = DateTime.now();
    final row = await database.into(database.transactions).insertReturning(
        TransactionsCompanion.insert(
            description: description,
            category_id: categoryId,
            amount: amount,
            transaction_date: date,
            created_at: now,
            updated_at: now));
  }

  @override
  void initState() {
    // Check if editing existing transaction
    if (widget.transactionsWithCategory != null) {
      updateTransaction(widget.transactionsWithCategory!);
    } else {
      type = 2;
      dateController.text = "";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Transaction")),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    value: isExpense,
                    inactiveTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.green,
                    activeColor: Colors.red,
                    onChanged: (bool value) {
                      setState(() {
                        isExpense = value;
                        type = (isExpense) ? 2 : 1;
                        selectedCategory = null;
                      });
                    },
                  ),
                  Text(
                    isExpense ? "Expense" : "Income",
                    style: GoogleFonts.montserrat(fontSize: 14),
                  )
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Amount',
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Category", style: GoogleFonts.montserrat()),
              ),
              SizedBox(height: 5),
              FutureBuilder<List<Category>>(
                future: getAllCategory(type),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    List<DropdownMenuItem<Category>> dropdownItems = [];
                    dropdownItems.add(DropdownMenuItem<Category>(
                      value: null,
                      child: Text("Pilih kategori"),
                    ));
                    dropdownItems.addAll(snapshot.data!.map((Category value) {
                      return DropdownMenuItem<Category>(
                        value: value,
                        child: Text(value.name),
                      );
                    }).toList());
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<Category>(
                        isExpanded: true,
                        value: selectedCategory,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        onChanged: (Category? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                        items: dropdownItems,
                      ),
                    );
                  } else {
                    return Text("No categories available");
                  }
                },
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: "Enter Date"),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      setState(() {
                        dateController.text = formattedDate;
                      });
                    } else {
                      print("Date is not selected");
                    }
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Description',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Check if editing existing transaction
                    if (widget.transactionsWithCategory != null) {
                      updateTransactionInDatabase();
                    } else {
                      // Check if all fields are filled
                      if (amountController.text.isEmpty ||
                          selectedCategory == null ||
                          dateController.text.isEmpty ||
                          descriptionController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Please fill in all fields"),
                        ));
                      } else {
                        saveTransactionToDatabase();
                      }
                    }
                  },
                  child: Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  void updateTransaction(TransactionWithCategory initTransaction) {
    amountController.text = initTransaction.transaction.amount.toString();
    descriptionController.text =
        initTransaction.transaction.description.toString();
    dateController.text = DateFormat('yyyy-MM-dd')
        .format(initTransaction.transaction.transaction_date);
    type = initTransaction.category.type;
    (type == 2) ? isExpense = true : isExpense = false;
    selectedCategory = initTransaction.category;
  }

  // void saveTransactionToDatabase() {
  //   insert(
  //     descriptionController.text,
  //     selectedCategory!.id,
  //     int.parse(amountController.text),
  //     DateTime.parse(dateController.text),
  //   );
  //   Navigator.pop(context, true);
  // }

void saveTransactionToDatabase() {
    insert(
      descriptionController.text,
      selectedCategory!.id,
      int.parse(amountController.text),
      DateTime.parse(dateController.text),
    ).then((_) {
      Navigator.pop(
          context, true); // Signal to HomePage that a transaction is saved
    });
  }


  void updateTransactionInDatabase() {
    int transactionId = widget.transactionsWithCategory!.transaction.id;
    database.updateTransactionRepo(
      transactionId,
      descriptionController.text,
      selectedCategory!.id,
      int.parse(amountController.text),
      DateTime.parse(dateController.text),
    );
    Navigator.pop(context, true);
  }
}
