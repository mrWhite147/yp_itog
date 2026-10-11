import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../state/cart_notifier.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Корзина пуста. Пора за покупками!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (c, i) {
                      final item = cart.items[i];
                      final isMaxStock = item.quantity >= item.product.stockCount;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.product.price} ₽ / шт.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'В наличии: ${item.product.stockCount} шт.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMaxStock ? Colors.orange.shade800 : Colors.black54,
                                      fontWeight: isMaxStock ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => cart.decrement(item.product.id),
                                  tooltip: 'Уменьшить на 1',
                                ),

                                SizedBox(
                                  width: 55,
                                  height: 40,
                                  child: TextFormField(
                                    key: ValueKey('${item.product.id}_${item.quantity}'),
                                    initialValue: '${item.quantity}',
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(),
                                    ),
                                    onFieldSubmitted: (val) {
                                      final parsed = int.tryParse(val) ?? 1;
                                      if (parsed > item.product.stockCount) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Максимум в наличии: ${item.product.stockCount} шт.',
                                            ),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                      cart.setQuantity(item.product.id, parsed);
                                    },
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: isMaxStock
                                      ? null
                                      : () => cart.increment(item.product.id),
                                  tooltip: isMaxStock
                                      ? 'Больше нет в наличии'
                                      : 'Увеличить на 1',
                                ),
                              ],
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              width: 90,
                              child: Text(
                                '${item.total} ₽',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => cart.removeItem(item.product.id),
                              tooltip: 'Удалить из корзины',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итого без скидки:'),
                          Text('${cart.totalPrice} ₽'),
                        ],
                      ),
                      if (cart.discount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Скидка по карте (5%):'),
                            Text(
                              '-${cart.discount} ₽',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'К ОПЛАТЕ:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Text(
                            '${cart.finalPrice} ₽',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final success = await cart.checkout(context);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Заказ успешно оформлен! Товары списаны со склада.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              context.go('/storefront');
                            }
                          },
                          child: const Text('Оформить заказ', style: TextStyle(fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}