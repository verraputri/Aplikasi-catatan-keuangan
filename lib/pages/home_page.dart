import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uangkoo/models/database.dart';
import 'package:uangkoo/models/transaction_with_category.dart';
import 'package:uangkoo/pages/category_page.dart';
import 'package:uangkoo/pages/transaction_page.dart';

class HomePage extends StatefulWidget {
  final DateTime selectedDate;
  const HomePage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDb database = AppDb();

  @override
  void initState() {
    super.initState();
  }

  Future<int> _getTotalIncome() async {
    return await database.getTotalIncome();
  }

  Future<int> _getTotalExpense() async {
    return await database.getTotalExpense();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<int>(
                          future: _getTotalIncome(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error');
                            } else {
                              return _buildIncomeExpenseWidget(
                                'Income',
                                snapshot.data ?? 0,
                                Icons.download,
                                Colors.greenAccent[400]!,
                              );
                            }
                          },
                        ),
                        FutureBuilder<int>(
                          future: _getTotalExpense(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error');
                            } else {
                              return _buildIncomeExpenseWidget(
                                'Expense',
                                snapshot.data ?? 0,
                                Icons.upload,
                                Colors.redAccent[400]!,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Transactions",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // StreamBuilder<List<TransactionWithCategory>>(
            //   stream: database.getTransactionByDateRepo(widget.selectedDate),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return Center(child: CircularProgressIndicator());
            //     } else {
            //       if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            //         return ListView.builder(
            //           physics: NeverScrollableScrollPhysics(),
            //           shrinkWrap: true,
            //           itemCount: snapshot.data!.length,
            //           itemBuilder: (context, index) {
            //             return _buildTransactionItem(snapshot.data![index]);
            //           },
            //         );
            //       } else {
            //         return Center(
            //           child: Column(
            //             children: [
            //               SizedBox(height: 30),
            //               Text(
            //                 "Belum ada transaksi",
            //                 style: GoogleFonts.montserrat(),
            //               ),
            //             ],
            //           ),
            //         );
            //       }
            //     }
            //   },
            // ),

            FutureBuilder<List<TransactionWithCategory>>(
              future:
                  database.getTransactionByDateRepo(widget.selectedDate).first,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final List<TransactionWithCategory>? transactions =
                      snapshot.data;
                  if (transactions != null && transactions.isNotEmpty) {
                    return ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(transactions[index]);
                      },
                    );
                  } else {
                    return Center(
                      child: Column(
                        children: [
                          SizedBox(height: 30),
                          Text(
                            "Belum ada transaksi",
                            style: GoogleFonts.montserrat(),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseWidget(
      String title, int amount, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Rp ${NumberFormat("#,##0", "id_ID").format(amount)}',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionWithCategory transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 10,
        child: ListTile(
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Konfirmasi Hapus Data'),
                        content: Text(
                            'Apakah Anda yakin ingin menghapus data transaksi ini?'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Batal'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Hapus'),
                            onPressed: () async {
                              await database.deleteTransactionRepo(
                                  transaction.transaction.id);
                              Navigator.of(context).pop();
                              setState(() {}); // Refresh the UI
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => TransactionPage(
                        transactionsWithCategory: transaction,
                      ),
                    ),
                  )
                      .then((value) {
                    setState(() {}); // Refresh the UI after edit
                  });
                },
              ),
            ],
          ),
          subtitle: Text(transaction.category.name),
          leading: Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: transaction.category.type == 1
                ? Icon(Icons.download, color: Colors.greenAccent[400])
                : Icon(Icons.upload, color: Colors.red[400]),
          ),
          title: Text(transaction.transaction.amount.toString()),
        ),
      ),
    );
  }
}
