import 'package:flutter/material.dart';
import '../models/food_item.dart';

import '../models/order.dart';

class CartItem {
  final FoodItem item;
  int quantity;
  CartItem({required this.item, this.quantity = 1});
}

class CartController extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Order? _editingOrder;

  Order? get editingOrder => _editingOrder;

  void setEditingOrder(Order? order) {
    _editingOrder = order;
    notifyListeners();
  }

  List<CartItem> get items => _items.values.toList(growable: false);
  int get totalItems => _items.values.fold(0, (sum, e) => sum + e.quantity);
  double get totalPrice => _items.values.fold(0.0, (sum, e) => sum + e.item.price * e.quantity);

  void add(FoodItem item) {
    final existing = _items[item.id];
    if (existing != null) {
      existing.quantity += 1;
    } else {
      _items[item.id] = CartItem(item: item, quantity: 1);
    }
    notifyListeners();
  }

  void setQuantity(FoodItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item.id);
      notifyListeners();
      return;
    }
    final existing = _items[item.id];
    if (existing != null) {
      existing.quantity = quantity;
    } else {
      _items[item.id] = CartItem(item: item, quantity: quantity);
    }
    notifyListeners();
  }

  void removeOne(String id) {
    final existing = _items[id];
    if (existing == null) return;
    existing.quantity -= 1;
    if (existing.quantity <= 0) {
      _items.remove(id);
    }
    notifyListeners();
  }

  int quantityFor(String id) => _items[id]?.quantity ?? 0;

  void removeAll(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _editingOrder = null;
    notifyListeners();
  }
}

class CartProvider extends InheritedNotifier<CartController> {
  final CartController controller;
  const CartProvider({super.key, required this.controller, required super.child})
      : super(notifier: controller);

  static CartController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<CartProvider>();
    assert(provider != null, 'CartProvider not found in context');
    return provider!.controller;
  }

  @override
  bool updateShouldNotify(covariant InheritedNotifier<CartController> oldWidget) => true;
}
