import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final location = GoRouterState.of(context).uri.path;
    final auth = context.watch<AuthNotifier>();
    final isManager = auth.hasRole(Role.manager);

    final destinations = isManager ? [
      const NavigationDestination(icon: Icon(Icons.analytics), label: 'Дашборд'),
      const NavigationDestination(icon: Icon(Icons.devices), label: 'Товары'),
      const NavigationDestination(icon: Icon(Icons.category), label: 'Категории'),
      const NavigationDestination(icon: Icon(Icons.business), label: 'Бренды'),
      const NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Поставщики'),
      const NavigationDestination(icon: Icon(Icons.people), label: 'Покупатели'),
      const NavigationDestination(icon: Icon(Icons.list_alt), label: 'Заказы'),
    ] : [
      const NavigationDestination(icon: Icon(Icons.storefront), label: 'Витрина'),
      const NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Корзина'),
    ];

    int currentIndex = 0;
    if (isManager) {
      if (location.startsWith('/products')) {
        currentIndex = 1;
      } else if (location.startsWith('/categories')) {
        currentIndex = 2;
      } else if (location.startsWith('/manufacturers')) {
        currentIndex = 3;
      } else if (location.startsWith('/suppliers')) {
        currentIndex = 4;
      } else if (location.startsWith('/customers')) {
        currentIndex = 5;
      } else if (location.startsWith('/orders')) {
        currentIndex = 6;
      }
    } else {
      if (location.startsWith('/cart')) {
        currentIndex = 1;
      }
    }

    void onNavigate(int index) {
      if (isManager) {
        if (index == 0) { context.go('/'); }
        if (index == 1) { context.go('/products'); }
        if (index == 2) { context.go('/categories'); }
        if (index == 3) { context.go('/manufacturers'); }
        if (index == 4) { context.go('/suppliers'); }
        if (index == 5) { context.go('/customers'); }
        if (index == 6) { context.go('/orders'); }
      } else {
        if (index == 0) { context.go('/'); }
        if (index == 1) { context.go('/cart'); }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин Электроники'),
        actions: [
          Center(child: Text(auth.user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout(), tooltip: 'Выйти'),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onNavigate,
                labelType: width > 1300 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
                destinations: destinations.map((d) => NavigationRailDestination(icon: d.icon, label: Text(d.label))).toList(),
              ),
            if (!isMobile) const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onNavigate,
              destinations: destinations,
            )
          : null,
    );
  }
}