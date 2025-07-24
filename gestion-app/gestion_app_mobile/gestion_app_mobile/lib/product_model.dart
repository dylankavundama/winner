class Product {
  final int id;
  final String name;
  final double prixVente;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    required this.prixVente,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.parse(json['id'].toString()), // Ensure parsing to int
      name: json['name'] as String,
      prixVente: double.parse(json['prix_vente'].toString()), // Match PHP key
      quantity: int.parse(json['quantity'].toString()), // Match PHP key
    );
  }

  // It's good practice to override equals and hashCode for custom objects
  // especially when used in collections or widgets that compare values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SaleProduct {
  final int id;
  final String name;
  final double prixVente; // Original selling price
  final int quantity; // Available stock
  int quantityToSell; // Quantity user wants to sell
  double priceOverride; // Price user sets for this sale item

  SaleProduct({
    required this.id,
    required this.name,
    required this.prixVente,
    required this.quantity,
    this.quantityToSell = 1,
    required this.priceOverride,
  });

  double get subtotal => quantityToSell * priceOverride;
}