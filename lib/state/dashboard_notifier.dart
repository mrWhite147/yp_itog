import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../repositories/repository_interfaces.dart';

class DashboardNotifier extends ChangeNotifier {
  final Repository<Order, EntityQuery> orderRepo;
  final Repository<Product, ProductQuery> productRepo;

  DashboardNotifier(this.orderRepo, this.productRepo);

  bool isLoading = true;
  int totalOrders = 0;
  double totalRevenue = 0.0;
  int lowStockProducts = 0;

  Future<void> loadStats() async {
    isLoading = true;
    notifyListeners();

    try {
      final ordersPage = await orderRepo.find(const EntityQuery(size: 1000));
      totalOrders = ordersPage.total;
      totalRevenue = ordersPage.items.fold(0, (sum, o) => sum + o.totalAmount);

      final lowStockPage = await productRepo.find(const ProductQuery(stockMax: 5));
      lowStockProducts = lowStockPage.total;
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }
}