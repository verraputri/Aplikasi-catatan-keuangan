import 'dart:io';

import 'package:drift/drift.dart';
// These imports are only needed to open the database
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uangkoo/models/category.dart';
import 'package:uangkoo/models/transaction.dart';
import 'package:uangkoo/models/transaction_with_category.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  // CRUD Category
  Future<List<Category>> getAllCategoryRepo(int type) async {
    return await (select(categories)..where((tbl) => tbl.type.equals(type)))
        .get();
  }

  Future updateCategoryRepo(int id, String newName) async {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(newName),
      ),
    );
  }

  Future deleteCategoryRepo(int id) async {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  // CRUD Transaction
  Stream<List<TransactionWithCategory>> getTransactionByDateRepo(
      DateTime date) {
    final query = (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id))
    ])
      ..where(transactions.transaction_date.equals(date)));
    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          row.readTable(transactions),
          row.readTable(categories),
        );
      }).toList();
    });
  }

    Future updateTransactionRepo(int id, String description, int categoryId,
      int amount, DateTime date) async {
    await (update(transactions)..where((t) => t.id.equals(id)))
        .write(TransactionsCompanion(
      description: Value(description),
      category_id: Value(categoryId),
      amount: Value(amount),
      transaction_date: Value(date),
      updated_at: Value(DateTime.now()),
    ));
  }


  Future<int> getTotalIncome() async {
    final result = await (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id))
    ])
          ..where(categories.type.equals(1)))
        .get();
    return result.fold<int>(0, (previousValue, element) {
      return previousValue + element.readTable(transactions).amount;
    });
  }

  Future<int> getTotalExpense() async {
    final result = await (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id))
    ])
          ..where(categories.type.equals(2)))
        .get();
    return result.fold<int>(0, (previousValue, element) {
      return previousValue + element.readTable(transactions).amount;
    });
  }
  
  Future deleteTransactionRepo(int id) async {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}