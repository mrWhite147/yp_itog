import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../state/list_notifier.dart';
import '../state/auth_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/dynamic_form.dart';
import '../widgets/debounced_search.dart';
import '../widgets/pagination_controls.dart';
import '../repositories/repository_interfaces.dart';
import '../core/api_exceptions.dart';
import '../main.dart'; 
import '../utils/validators.dart';

class ProductListScreen extends StatefulWidget {
  final ProductQuery query;
  const ProductListScreen({super.key, required this.query});
  @override State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override void initState() { super.initState(); _load(); }
  @override void didUpdateWidget(covariant ProductListScreen oldWidget) { super.didUpdateWidget(oldWidget); if (widget.query != oldWidget.query) _load(); }
  void _load() => WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ListNotifier<Product, ProductQuery>>().load(widget.query));
  void _updateUrl(ProductQuery q) => context.go(Uri(path: '/products', queryParameters: q.toMap()).toString());

  void _confirmDelete(BuildContext context, ListNotifier<Product, ProductQuery> notifier, AuthNotifier auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление'),
        content: Text('Удалить выбранные элементы (${notifier.selected.length} шт.)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(onPressed: () { notifier.deleteSelected(widget.query, hard: false); Navigator.pop(ctx); }, child: const Text('В корзину')),
          if (auth.hasRole(Role.admin))
            TextButton(onPressed: () { notifier.deleteSelected(widget.query, hard: true); Navigator.pop(ctx); }, child: const Text('Удалить навсегда', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Product, ProductQuery>>();
    final auth = context.watch<AuthNotifier>();
    final cache = context.watch<DictionaryCache>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Товары'), actions: [
        if (auth.hasRole(Role.manager))
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Создать'), onPressed: () => context.push('/products/new')),
        const SizedBox(width: 16),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0), 
          child: Wrap(
            spacing: 16, 
            runSpacing: 16, 
            crossAxisAlignment: WrapCrossAlignment.center, 
            children: [
              SizedBox(width: 200, child: DebouncedSearch(initialValue: widget.query.search, onChanged: (val) => _updateUrl(ProductQuery(search: val, categoryId: widget.query.categoryId, priceFrom: widget.query.priceFrom, priceTo: widget.query.priceTo, includeDeleted: widget.query.includeDeleted, page: 1, size: widget.query.size)))),
              
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: widget.query.categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Категория', 
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null, 
                      child: Text('Все категории', overflow: TextOverflow.ellipsis),
                    ),
                    ...cache.categories.map((c) => DropdownMenuItem(
                      value: c.id, 
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (val) => _updateUrl(ProductQuery(
                    categoryId: val, 
                    search: widget.query.search, 
                    priceFrom: widget.query.priceFrom, 
                    priceTo: widget.query.priceTo, 
                    includeDeleted: widget.query.includeDeleted, 
                    page: 1, 
                    size: widget.query.size,
                  )),
                ),
              ),

              SizedBox(width: 120, child: TextFormField(initialValue: widget.query.priceFrom?.toString(), decoration: const InputDecoration(labelText: 'Цена от', border: OutlineInputBorder()), onFieldSubmitted: (val) => _updateUrl(ProductQuery(priceFrom: double.tryParse(val), categoryId: widget.query.categoryId, search: widget.query.search, priceTo: widget.query.priceTo, includeDeleted: widget.query.includeDeleted, page: 1)))),
              SizedBox(width: 120, child: TextFormField(initialValue: widget.query.priceTo?.toString(), decoration: const InputDecoration(labelText: 'Цена до', border: OutlineInputBorder()), onFieldSubmitted: (val) => _updateUrl(ProductQuery(priceTo: double.tryParse(val), categoryId: widget.query.categoryId, search: widget.query.search, priceFrom: widget.query.priceFrom, includeDeleted: widget.query.includeDeleted, page: 1)))),
              SizedBox(width: 180, child: CheckboxListTile(title: const Text('С удаленными'), value: widget.query.includeDeleted, onChanged: (val) => _updateUrl(ProductQuery(includeDeleted: val ?? false, categoryId: widget.query.categoryId, search: widget.query.search, priceFrom: widget.query.priceFrom, priceTo: widget.query.priceTo, page: 1)), controlAffinity: ListTileControlAffinity.leading)),
            ],
          ),
        ),
        if (notifier.hasSelection && auth.hasRole(Role.manager))
          Container(color: Colors.blue.shade50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [Text('Выбрано: ${notifier.selected.length}', style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), FilledButton.icon(icon: const Icon(Icons.delete), label: const Text('Удалить'), style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _confirmDelete(context, notifier, auth))])),
        Expanded(child: _buildBody(notifier, auth)),
      ]),
    );
  }

  Widget _buildBody(ListNotifier<Product, ProductQuery> notifier, AuthNotifier auth) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading: return const Center(child: CircularProgressIndicator());
      case LoadStatus.error: return Center(child: Text('Ошибка: ${notifier.error}', style: const TextStyle(color: Colors.red)));
      case LoadStatus.empty: return const Center(child: Text('Ничего не найдено. Попробуйте изменить фильтры.'));
      case LoadStatus.success:
        return Column(children: [
          Expanded(child: EntityTable<Product>(
            items: notifier.result.items, idOf: (p) => p.id, isDeletedOf: (p) => p.isDeleted, selected: notifier.selected, 
            onToggleSelect: auth.hasRole(Role.manager) ? notifier.toggleSelection : null,
            sortField: widget.query.sortField, sortAscending: widget.query.sortAscending,
            onSort: (field) => _updateUrl(ProductQuery(sortField: field, sortAscending: field == widget.query.sortField ? !widget.query.sortAscending : true, categoryId: widget.query.categoryId, search: widget.query.search, priceFrom: widget.query.priceFrom, priceTo: widget.query.priceTo, includeDeleted: widget.query.includeDeleted, page: 1, size: widget.query.size)),
            columns: [TableColumnSpec(label: 'Название', sortField: 'name', build: (p) => Text(p.name)), TableColumnSpec(label: 'Артикул', build: (p) => Text(p.sku)), TableColumnSpec(label: 'Цена (₽)', sortField: 'price', build: (p) => Text('${p.price}')), TableColumnSpec(label: 'Остаток', sortField: 'stock', build: (p) => Text('${p.stockCount} шт.'))],
            actions: (p) => [
              if (auth.hasRole(Role.manager)) IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/products/${p.id}/edit'), tooltip: 'Редактировать'),
              if (p.isDeleted && auth.hasRole(Role.admin)) IconButton(icon: const Icon(Icons.restore), onPressed: () => notifier.restore(p.id, widget.query), tooltip: 'Восстановить')
            ],
          )),
          Padding(padding: const EdgeInsets.all(8.0), child: PaginationControls(page: notifier.result.page, totalPages: notifier.result.totalPages, totalItems: notifier.result.total, size: notifier.result.size, hasPrevious: notifier.result.hasPrevious, hasNext: notifier.result.hasNext, onPageChanged: (p) => _updateUrl(ProductQuery(page: p, size: widget.query.size, categoryId: widget.query.categoryId, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending, priceFrom: widget.query.priceFrom, priceTo: widget.query.priceTo, includeDeleted: widget.query.includeDeleted)), onSizeChanged: (s) => _updateUrl(ProductQuery(size: s, page: 1, categoryId: widget.query.categoryId, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending, priceFrom: widget.query.priceFrom, priceTo: widget.query.priceTo, includeDeleted: widget.query.includeDeleted)))),
        ]);
    }
  }
}

class ProductFormScreen extends StatefulWidget {
  final String? id; const ProductFormScreen({super.key, this.id});
  @override State<ProductFormScreen> createState() => _ProductFormScreenState();
}
class _ProductFormScreenState extends State<ProductFormScreen> {
  Product? _product; Map<String, String> _serverErrors = {}; bool _isLoading = true;
  @override void initState() { super.initState(); _loadData(); }
  
  Future<void> _loadData() async {
    if (widget.id == null) { setState(() { _product = const Product(id: '', name: '', sku: '', price: 0, stockCount: 0, manufacturerId: '', categoryIds: [], supplierIds: []); _isLoading = false; }); return; }
    try { 
      final p = await context.read<Repository<Product, ProductQuery>>().findById(widget.id!); 
      setState(() { _product = p; _isLoading = false; }); 
    } catch (e) { 
      if (!mounted) return;
      context.pop(); 
    }
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {}); 
    try {
      final repo = context.read<Repository<Product, ProductQuery>>();
      widget.id == null ? await repo.create(_product!) : await repo.update(widget.id!, _product!);
      if (mounted) context.pop(); 
    } on ValidationException catch (e) { setState(() => _serverErrors = e.errors); throw Exception('Validation failed'); } 
    catch (e, stacktrace) { if (mounted) showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Критическая системная ошибка'), content: SingleChildScrollView(child: Text('$e\n\n$stacktrace')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОК'))])); throw Exception('System Error'); }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading || _product == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cache = context.watch<DictionaryCache>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Новый товар' : 'Редактирование товара')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), 
          child: Padding(
            padding: const EdgeInsets.all(24), 
            child: DynamicForm(
              serverErrors: _serverErrors, 
              onSave: _save, 
              fields: [
                FormFieldSpec(name: 'name', label: 'Название товара', type: FieldType.text, initialValue: _product!.name, validator: Validators.required, onSaved: (v) => _product = _product!.copyWith(name: v)),
                FormFieldSpec(name: 'sku', label: 'Артикул (Уникальный)', type: FieldType.text, initialValue: _product!.sku, validator: Validators.required, onSaved: (v) => _product = _product!.copyWith(sku: v)),
                FormFieldSpec(name: 'price', label: 'Цена (₽)', type: FieldType.number, initialValue: _product!.price, validator: Validators.combine([Validators.required, Validators.positiveNumber]), onSaved: (v) => _product = _product!.copyWith(price: double.parse(v.replaceAll(',', '.')))),
                FormFieldSpec(name: 'stockCount', label: 'Остаток на складе (шт.)', type: FieldType.number, initialValue: _product!.stockCount, validator: Validators.combine([Validators.required, Validators.positiveInteger]), onSaved: (v) => _product = _product!.copyWith(stockCount: int.parse(v))),
                FormFieldSpec(name: 'manufacturerId', label: 'Производитель (Бренд)', type: FieldType.dropdown, initialValue: _product!.manufacturerId, options: cache.manufacturers, optionLabelBuilder: (m) => (m as Manufacturer).name, validator: (v) => v == null || v == '' ? 'Выберите производителя' : null, onSaved: (v) => _product = _product!.copyWith(manufacturerId: v)),
                FormFieldSpec(name: 'categoryIds', label: 'Категории', type: FieldType.multiSelect, initialValue: _product!.categoryIds, options: cache.categories, optionLabelBuilder: (c) => (c as Category).name, onSaved: (v) => _product = _product!.copyWith(categoryIds: (v as List).cast<String>())),
                FormFieldSpec(name: 'supplierIds', label: 'Поставщики', type: FieldType.multiSelect, initialValue: _product!.supplierIds, options: cache.suppliers, optionLabelBuilder: (s) => (s as Supplier).name, onSaved: (v) => _product = _product!.copyWith(supplierIds: (v as List).cast<String>())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}