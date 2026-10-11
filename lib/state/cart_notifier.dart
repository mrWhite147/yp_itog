import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../repositories/repository_interfaces.dart';
import 'auth_notifier.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem(this.product, {this.quantity = 1});
  double get total => product.price * quantity;
}

class CartNotifier extends ChangeNotifier {
  final Repository<Order, EntityQuery> orderRepo;
  final AuthNotifier auth;

  CartNotifier(this.orderRepo, this.auth);

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int getQuantityInCart(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    return index != -1 ? _items[index].quantity : 0;
  }

  bool addItem(Product p) {
    final index = _items.indexWhere((i) => i.product.id == p.id);
    if (index != -1) {
      if (_items[index].quantity < p.stockCount) {
        _items[index].quantity++;
        notifyListeners();
        return true;
      }
      return false;
    } else {
      if (p.stockCount > 0) {
        _items.add(CartItem(p));
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  bool increment(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index != -1) {
      final item = _items[index];
      if (item.quantity < item.product.stockCount) {
        item.quantity++;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void decrement(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index != -1) {
      final maxStock = _items[index].product.stockCount;
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else if (newQuantity > maxStock) {
        _items[index].quantity = maxStock;
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.total);

  double get discount {
    if (auth.hasRole(Role.customer) && _items.isNotEmpty) {
      return totalPrice * 0.05;
    }
    return 0;
  }

  double get finalPrice => totalPrice - discount;

  Future<bool> checkout(BuildContext context) async {
    if (_items.isEmpty) return false;

    final productRepo = context.read<Repository<Product, ProductQuery>>();

    for (final item in _items) {
      if (item.quantity > item.product.stockCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Товара "${item.product.name}" недостаточно на складе!'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    try {
      for (final item in _items) {
        final newStock = item.product.stockCount - item.quantity;
        await productRepo.update(
          item.product.id,
          item.product.copyWith(stockCount: newStock),
        );
      }

      final newOrder = Order(
        id: '',
        customerId: auth.user?.id.toString() ?? '',
        totalAmount: finalPrice,
        status: 'new',
        createdAt: DateTime.now(),
      );
      await orderRepo.create(newOrder);

      clear();
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при оформлении заказа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}