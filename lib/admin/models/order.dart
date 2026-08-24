import '../../models/food_item.dart';

enum OrderStatus { pending, cooking, completed }

class OrderItem {
  final FoodItem item;
  final int quantity;
  const OrderItem({required this.item, required this.quantity});
}

class Order {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final String? orderType;
  OrderStatus status;
  final List<OrderItem> items;
  final double? customerLat;
  final double? customerLong;
  final bool isEdited;
  final String? note;

  Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    this.orderType,
    this.status = OrderStatus.pending,
    this.customerLat,
    this.customerLong,
    this.isEdited = false,
    this.note,
  });

  double get totalPrice => items.fold(0.0, (sum, e) => sum + e.item.price * e.quantity);
}
