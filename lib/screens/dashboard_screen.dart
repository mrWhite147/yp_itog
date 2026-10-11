import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_notifier.dart';
import '../widgets/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DashboardNotifier>().loadStats());
  }

  @override Widget build(BuildContext context) {
    final dash = context.watch<DashboardNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Панель управления (Аналитика)')),
      body: dash.isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text('Сводка по продажам', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  
                  Wrap(spacing: 16, runSpacing: 16, children: [
                    _StatCard(title: 'Заказов за месяц', value: '${dash.totalOrders}', icon: Icons.shopping_cart),
                    _StatCard(title: 'Общая выручка', value: '${dash.totalRevenue} ₽', icon: Icons.attach_money, color: Colors.green),
                    _StatCard(title: 'Товаров критически мало', value: '${dash.lowStockProducts}', icon: Icons.warning, color: Colors.red),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Аналитическое распределение (fl_chart): Заказы vs Дефицит', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          RevenueChart(
                            totalOrders: dash.totalOrders, 
                            lowStock: dash.lowStockProducts,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('Управление', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  
                  Wrap(spacing: 16, runSpacing: 16, children: [
                    FilledButton.icon(icon: const Icon(Icons.devices), label: const Text('Товары'), onPressed: () => context.go('/products')),
                    FilledButton.icon(icon: const Icon(Icons.business), label: const Text('Бренды'), onPressed: () => context.go('/manufacturers')),
                    FilledButton.icon(icon: const Icon(Icons.category), label: const Text('Категории'), onPressed: () => context.go('/categories')),
                    FilledButton.icon(icon: const Icon(Icons.local_shipping), label: const Text('Поставщики'), onPressed: () => context.go('/suppliers')),
                    FilledButton.icon(icon: const Icon(Icons.people), label: const Text('Покупатели'), onPressed: () => context.go('/customers')),
                    FilledButton.icon(icon: const Icon(Icons.list_alt), label: const Text('Заказы'), onPressed: () => context.go('/orders')),
                  ]),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, this.color = Colors.blue});
  @override Widget build(BuildContext context) => Card(elevation: 2, child: Container(width: 250, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 32), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(color: Colors.grey)))]), const SizedBox(height: 16), Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color))])));
}