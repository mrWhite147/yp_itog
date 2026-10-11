import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../state/list_notifier.dart';
import '../state/cart_notifier.dart';
import 'package:go_router/go_router.dart';
class StorefrontScreen extends StatefulWidget {
  final ProductQuery query;
  const StorefrontScreen({super.key, required this.query});
  @override State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ListNotifier<Product, ProductQuery>>().load(widget.query));
  }

  @override Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Product, ProductQuery>>();
    final cart = context.watch<CartNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Каталог товаров')),
      body: notifier.status == LoadStatus.loading ? const Center(child: CircularProgressIndicator()) 
        : notifier.status == LoadStatus.error ? Center(child: Text(notifier.error ?? 'Ошибка', style: const TextStyle(color: Colors.red)))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: notifier.result.items.length,
            itemBuilder: (c, i) {
              final p = notifier.result.items[i];
              final inStock = p.stockCount > 0;
              return Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Center(child: Icon(Icons.devices_other, size: 80, color: Colors.grey.shade400))),
                      Text(p.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text('${p.price} ₽', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(inStock ? 'В наличии: ${p.stockCount}' : 'Нет в наличии', style: TextStyle(color: inStock ? Colors.black54 : Colors.red)),
                      const Spacer(),
                      SizedBox(width: double.infinity, child: FilledButton.icon(
                        icon: const Icon(Icons.shopping_cart), label: const Text('В корзину'),
                        onPressed: inStock ? () {
                          cart.addItem(p);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} добавлен в корзину'), duration: const Duration(seconds: 1)));
                        } : null,
                      ))
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cart'),
        icon: const Icon(Icons.shopping_bag),
        label: Text('${cart.items.length} шт. = ${cart.totalPrice} ₽'),
      ),
    );
  }
}