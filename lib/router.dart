import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'state/auth_notifier.dart';
import 'state/list_notifier.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'screens/auth_screens.dart';
import 'screens/storefront_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_screens.dart';
import 'screens/manufacturer_screens.dart';
import 'screens/category_screens.dart';
import 'screens/supplier_screens.dart';
import 'screens/customer_screens.dart';
import 'screens/order_screens.dart';
import 'widgets/responsive_shell.dart';
import 'screens/users_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/register';
      if (path.startsWith('/admin/users') && !auth.hasRole(Role.admin)) {
        return '/forbidden';
      }

      if (!loggedIn && !isAuthRoute) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (loggedIn && isAuthRoute) {
        return '/';
      }

      final isManagerRoute = path.startsWith('/products') ||
                             path.startsWith('/manufacturers') ||
                             path.startsWith('/categories') ||
                             path.startsWith('/suppliers') ||
                             path.startsWith('/customers') ||
                             path.startsWith('/orders') ||
                             path.startsWith('/dashboard');

      final isForm = path.endsWith('/new') || path.contains('/edit');

      if ((isManagerRoute || isForm) && !auth.hasRole(Role.manager)) {
        if (path.startsWith('/storefront') || path.startsWith('/cart') || path == '/') {
          return null;
        }
        return '/forbidden';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),

      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(path: '/admin/users', builder: (c, s) => const UsersScreen()),
          GoRoute(
            path: '/',
            builder: (c, s) => auth.hasRole(Role.manager)
                ? const DashboardScreen()
                : ChangeNotifierProvider(
                    create: (_) => ListNotifier<Product, ProductQuery>(c.read()),
                    child: const StorefrontScreen(query: ProductQuery()),
                  ),
          ),
          GoRoute(
            path: '/storefront',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Product, ProductQuery>(c.read()),
              child: StorefrontScreen(query: ProductQuery.fromMap(s.uri.queryParameters)),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Product, ProductQuery>(c.read()),
              child: ProductListScreen(query: ProductQuery.fromMap(s.uri.queryParameters)),
            ),
          ),
          GoRoute(
            path: '/manufacturers',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Manufacturer, ManufacturerQuery>(c.read()),
              child: ManufacturerListScreen(query: ManufacturerQuery.fromMap(s.uri.queryParameters)),
            ),
          ),
          GoRoute(
            path: '/categories',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Category, EntityQuery>(c.read()),
              child: CategoryListScreen(query: EntityQuery.fromMap(s.uri.queryParameters)),
            ),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Supplier, EntityQuery>(c.read()),
              child: SupplierListScreen(query: EntityQuery.fromMap(s.uri.queryParameters)),
            ),
          ),
          GoRoute(
            path: '/customers',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Customer, EntityQuery>(c.read()),
              child: CustomerListScreen(query: EntityQuery.fromMap(s.uri.queryParameters)),
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (c, s) => ChangeNotifierProvider(
              create: (_) => ListNotifier<Order, EntityQuery>(c.read()),
              child: OrderListScreen(query: EntityQuery.fromMap(s.uri.queryParameters)),
            ),
          ),

          GoRoute(path: '/products/new', builder: (c, s) => const ProductFormScreen()),
          GoRoute(path: '/products/:id/edit', builder: (c, s) => ProductFormScreen(id: s.pathParameters['id'])),

          GoRoute(path: '/manufacturers/new', builder: (c, s) => const ManufacturerFormScreen()),
          GoRoute(path: '/manufacturers/:id/edit', builder: (c, s) => ManufacturerFormScreen(id: s.pathParameters['id'])),

          GoRoute(path: '/categories/new', builder: (c, s) => const CategoryFormScreen()),
          GoRoute(path: '/categories/:id/edit', builder: (c, s) => CategoryFormScreen(id: s.pathParameters['id'])),

          GoRoute(path: '/suppliers/new', builder: (c, s) => const SupplierFormScreen()),
          GoRoute(path: '/suppliers/:id/edit', builder: (c, s) => SupplierFormScreen(id: s.pathParameters['id'])),

          GoRoute(path: '/customers/new', builder: (c, s) => const CustomerFormScreen()),
          GoRoute(path: '/customers/:id/edit', builder: (c, s) => CustomerFormScreen(id: s.pathParameters['id'])),
        ],
      ),
    ],
  );
}