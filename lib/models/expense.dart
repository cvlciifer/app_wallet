
import 'package:app_wallet/library/main_library.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../sync_service/sync_service.dart';
import 'category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final formatter = DateFormat.yMd();
final uuid = Uuid();

class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    String? id,
    this.syncStatus = SyncStatus.synced,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;
  final SyncStatus syncStatus;

  String get formattedDate {
    return formatter.format(date);
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    SyncStatus? syncStatus,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory Expense.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      title: data['name'] ?? '',
      amount: (data['cantidad'] as num?)?.toDouble() ?? 0.0,
      date: (data['fecha'] is DateTime)
          ? data['fecha']
          : (data['fecha'] is Timestamp)
              ? (data['fecha'] as Timestamp).toDate()
              : DateTime.now(),
      category: Category.values.firstWhere(
        (c) => c.toString().split('.').last == (data['tipo'] ?? ''),
        orElse: () => Category.comida,
      ),
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': title,
      'cantidad': amount,
      'fecha': date,
      'tipo': category.toString().split('.').last,
    };
  }
}
 