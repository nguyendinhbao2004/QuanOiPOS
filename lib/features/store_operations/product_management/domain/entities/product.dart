import 'product_type.dart';

class Product {
  final int id;
  final int storeId;
  final int categoryId;
  final String categoryName;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final ProductType type;
  final bool isSell;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const Product({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.type,
    required this.isSell,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });
}
