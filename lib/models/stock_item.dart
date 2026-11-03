import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  final String id;
  final String sku;
  final String itemName;
  final String category;
  final int quantity;
  final double unitPrice;
  final int reorderLevel;
  final DateTime? createdAt;

  const StockItem({
    required this.id,
    required this.sku,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.reorderLevel,
    this.createdAt,
  });

  factory StockItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return StockItem(
      id: doc.id,
      sku: (data['sku'] as String?)?.trim() ?? '',
      itemName: (data['itemName'] as String?)?.trim() ?? '',
      category: (data['category'] as String?)?.trim() ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      reorderLevel: (data['reorderLevel'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isLowStock => quantity <= reorderLevel;
}
