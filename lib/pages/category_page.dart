import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uangkoo/models/category.dart';
import 'package:uangkoo/models/database.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool? isExpense;
  int? type;
  final AppDb database = AppDb();
  List<Category> listCategory = [];
  TextEditingController categoryNameController = TextEditingController();

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  Future insert(String name, int type) async {
    DateTime now = DateTime.now();
    await database.into(database.categories).insertReturning(
        CategoriesCompanion.insert(
            name: name, type: type, createdAt: now, updatedAt: now));
  }

  Future update(int categoryId, String newName) async {
    await database.updateCategoryRepo(categoryId, newName);
  }

  // Future deleteCategory(int categoryId) async {
  //   await database.deleteCategoryRepo(categoryId);
  // }

Future deleteCategory(int categoryId) async {
    // Hapus transaksi terkait
    await database.transaction(() async {
      await (database.delete(database.transactions)
            ..where((tbl) => tbl.category_id.equals(categoryId)))
          .go();
    });

    // Hapus kategori
    await database.deleteCategoryRepo(categoryId);
  }


  @override
  void initState() {
    isExpense = true;
    type = (isExpense!) ? 2 : 1;
    super.initState();
  }

  void openDialog(Category? category) {
    categoryNameController.clear();
    if (category != null) {
      categoryNameController.text = category.name;
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
                child: Center(
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ((category != null) ? 'Edit ' : 'Add ') +
                      ((isExpense!) ? "Outcome" : "Income"),
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: (isExpense!) ? Colors.red : Colors.green),
                ),
                SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: categoryNameController,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), hintText: "Name"),
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () {
                      if (categoryNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Silahkan isi kategori"),
                        ));
                      } else {
                        if (category == null) {
                          insert(
                              categoryNameController.text, isExpense! ? 2 : 1);
                        } else {
                          update(category.id, categoryNameController.text);
                        }
                        setState(() {});
                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                      }
                    },
                    child: Text("Save"))
              ],
            ))),
          );
        });
  }

  void confirmDelete(int categoryId) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi Penghapusan"),
            content: Text(
                "Apakah anda yakin ingin menghapus kategori ini? ini akan berdampak pada hilangnya data transaksi anda yang terkait dengan kategori ini."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog tanpa menghapus
                },
                child: Text("Tidak"),
              ),
              TextButton(
                onPressed: () {
                  deleteCategory(categoryId); // Hapus kategori
                  setState(() {});
                  Navigator.of(context).pop(); // Tutup dialog setelah menghapus
                },
                child: Text("Ya"),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: isExpense!,
                      inactiveTrackColor: Colors.green[200],
                      inactiveThumbColor: Colors.green,
                      activeColor: Colors.red,
                      onChanged: (bool value) {
                        setState(() {
                          isExpense = value;
                          type = (value) ? 2 : 1;
                        });
                      },
                    ),
                    Text(
                      isExpense! ? "Expense" : "Income",
                      style: GoogleFonts.montserrat(fontSize: 14),
                    )
                  ],
                ),
                IconButton(
                    onPressed: () {
                      openDialog(null);
                    },
                    icon: Icon(Icons.add))
              ],
            ),
          ),
          FutureBuilder<List<Category>>(
            future: getAllCategory(type!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (snapshot.hasData) {
                  if (snapshot.data!.length > 0) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
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
                                        confirmDelete(snapshot.data![index].id);
                                      },
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        openDialog(snapshot.data![index]);
                                      },
                                    )
                                  ],
                                ),
                                leading: Container(
                                    padding: EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: (isExpense!)
                                        ? Icon(Icons.upload,
                                            color: Colors.redAccent[400])
                                        : Icon(
                                            Icons.download,
                                            color: Colors.greenAccent[400],
                                          )),
                                title: Text(snapshot.data![index].name)),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text("No has data"),
                    );
                  }
                } else {
                  return Center(
                    child: Text("No has data"),
                  );
                }
              }
            },
          ),
        ])),
      ),
    );
  }
}


