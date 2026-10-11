import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'repositories/pb_repository.dart';
import 'repositories/repository_interfaces.dart';
import 'models/models.dart';
import 'models/queries.dart';
import 'state/auth_notifier.dart';
import 'state/cart_notifier.dart';
import 'state/dashboard_notifier.dart';
import 'widgets/inactivity_watcher.dart';
import 'router.dart';

class DictionaryCache extends ChangeNotifier {
  final Repository<Manufacturer, ManufacturerQuery> manRepo;
  final Repository<Category, EntityQuery> catRepo;
  final Repository<Supplier, EntityQuery> supRepo;
  List<Manufacturer> manufacturers = [];
  List<Category> categories = [];
  List<Supplier> suppliers = [];

  DictionaryCache(this.manRepo, this.catRepo, this.supRepo);

  Future<void> loadOnce() async {
    if (manufacturers.isEmpty) manufacturers = (await manRepo.find(const ManufacturerQuery(size: 100))).items;
    if (categories.isEmpty) categories = (await catRepo.find(const EntityQuery(size: 100))).items;
    if (suppliers.isEmpty) suppliers = (await supRepo.find(const EntityQuery(size: 100))).items;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  late AuthNotifier authNotifier;
  final dio = buildDio(getAuth: () => authNotifier);
  authNotifier = AuthNotifier(prefs, dio);

  await authNotifier.restore();
  final router = buildRouter(authNotifier);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<Dio>.value(value: dio),        
        ProxyProvider<Dio, Repository<Product, ProductQuery>>(update: (_, d, _) => PbRepository(d, 'products', Product.fromJson, (p) => p.toJson())),
        ProxyProvider<Dio, Repository<Manufacturer, ManufacturerQuery>>(update: (_, d, _) => PbRepository(d, 'manufacturers', Manufacturer.fromJson, (m) => m.toJson())),
        ProxyProvider<Dio, Repository<Customer, EntityQuery>>(update: (_, d, _) => PbRepository(d, 'customers', Customer.fromJson, (c) => c.toJson())),
        ProxyProvider<Dio, Repository<Category, EntityQuery>>(update: (_, d, _) => PbRepository(d, 'categories', Category.fromJson, (c) => c.toJson())),
        ProxyProvider<Dio, Repository<Supplier, EntityQuery>>(update: (_, d, _) => PbRepository(d, 'suppliers', Supplier.fromJson, (s) => s.toJson())),
        ProxyProvider<Dio, Repository<Order, EntityQuery>>(update: (_, d, _) => PbRepository(d, 'orders', Order.fromJson, (o) => o.toJson())),
        ChangeNotifierProxyProvider3<Repository<Manufacturer, ManufacturerQuery>, Repository<Category, EntityQuery>, Repository<Supplier, EntityQuery>, DictionaryCache>(
          create: (c) => DictionaryCache(c.read(), c.read(), c.read()),
          update: (_, m, c, s, prev) => (prev ?? DictionaryCache(m, c, s))..loadOnce(),
        ),

        ChangeNotifierProxyProvider<Repository<Order, EntityQuery>, CartNotifier>(
          create: (c) => CartNotifier(c.read<Repository<Order, EntityQuery>>(), authNotifier),
          update: (_, orderRepo, prev) => prev ?? CartNotifier(orderRepo, authNotifier),
        ),
        ChangeNotifierProxyProvider2<Repository<Order, EntityQuery>, Repository<Product, ProductQuery>, DashboardNotifier>(
          create: (c) => DashboardNotifier(c.read<Repository<Order, EntityQuery>>(), c.read<Repository<Product, ProductQuery>>()),
          update: (_, oRepo, pRepo, prev) => prev ?? DashboardNotifier(oRepo, pRepo),
        ),
      ],
      child: StoreApp(router: router),
    ),
  );
}

class StoreApp extends StatelessWidget {
  final RouterConfig<Object> router;
  const StoreApp({super.key, required this.router});

  @override Widget build(BuildContext context) {
    return InactivityWatcher(
      onLogout: () {
        context.read<AuthNotifier>().logout();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сессия завершена')));
      },
      child: MaterialApp.router(
        title: 'Магазин Электроники',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
        routerConfig: router,
      ),
    );
  }
}