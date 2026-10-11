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

class CategoryListScreen extends StatefulWidget {
  final EntityQuery query;
  const CategoryListScreen({super.key, required this.query});
  @override State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override void initState() { super.initState(); _load(); }
  @override void didUpdateWidget(covariant CategoryListScreen oldWidget) { super.didUpdateWidget(oldWidget); if (widget.query != oldWidget.query) _load(); }
  void _load() => WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ListNotifier<Category, EntityQuery>>().load(widget.query));
  void _updateUrl(EntityQuery q) => context.go(Uri(path: '/categories', queryParameters: q.toMap()).toString());

  @override Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Category, EntityQuery>>();
    final auth = context.watch<AuthNotifier>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Категории'), actions: [
        if (auth.hasRole(Role.manager)) 
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Создать'), onPressed: () => context.push('/categories/new')), 
        const SizedBox(width: 16)
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8), 
          child: Wrap(spacing: 16, runSpacing: 16, children: [
            SizedBox(width: 250, child: DebouncedSearch(initialValue: widget.query.search, onChanged: (v) => _updateUrl(EntityQuery(search: v, page: 1, size: widget.query.size)))),
            SizedBox(width: 200, child: CheckboxListTile(title: const Text('С удаленными'), value: widget.query.includeDeleted, onChanged: (v) => _updateUrl(EntityQuery(includeDeleted: v ?? false, page: 1)), controlAffinity: ListTileControlAffinity.leading)),
          ])
        ),
        if (notifier.hasSelection && auth.hasRole(Role.manager)) 
          Container(color: Colors.blue.shade50, padding: const EdgeInsets.all(8), child: Row(children: [Text('Выбрано: ${notifier.selected.length}'), const Spacer(), FilledButton(onPressed: () => notifier.deleteSelected(widget.query), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Удалить'))])),
        
        Expanded(child: notifier.status == LoadStatus.loading ? const Center(child: CircularProgressIndicator()) : EntityTable<Category>(
          items: notifier.result.items, idOf: (c) => c.id, isDeletedOf: (c) => c.isDeleted, selected: notifier.selected, onToggleSelect: auth.hasRole(Role.manager) ? notifier.toggleSelection : null, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending,
          onSort: (f) => _updateUrl(EntityQuery(sortField: f, sortAscending: f == widget.query.sortField ? !widget.query.sortAscending : true, page: 1, size: widget.query.size)),
          columns: [TableColumnSpec(label: 'Название', sortField: 'name', build: (c) => Text(c.name))],
          actions: (c) => [
            if (auth.hasRole(Role.manager)) IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/categories/${c.id}/edit')), 
            if (c.isDeleted && auth.hasRole(Role.admin)) IconButton(icon: const Icon(Icons.restore), onPressed: () => notifier.restore(c.id, widget.query))
          ],
        )),
        PaginationControls(page: notifier.result.page, totalPages: notifier.result.totalPages, totalItems: notifier.result.total, size: notifier.result.size, hasPrevious: notifier.result.hasPrevious, hasNext: notifier.result.hasNext, onPageChanged: (p) => _updateUrl(EntityQuery(page: p, size: widget.query.size, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending)), onSizeChanged: (s) => _updateUrl(EntityQuery(size: s, page: 1, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending))),
      ]),
    );
  }
}

class CategoryFormScreen extends StatefulWidget {
  final String? id; 
  const CategoryFormScreen({super.key, this.id});
  
  @override State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  Category? _cat; 
  Map<String, String> _serverErrors = {}; 
  bool _isLoading = true;
  
  @override void initState() { super.initState(); _load(); }
  
  Future<void> _load() async {
    if (widget.id == null) { 
      setState(() { _cat = const Category(id: '', name: ''); _isLoading = false; }); 
      return; 
    }
    try { 
      final c = await context.read<Repository<Category, EntityQuery>>().findById(widget.id!); 
      setState(() { _cat = c; _isLoading = false; }); 
    } catch (e) { 
      if (mounted) context.pop(); 
    }
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    try { 
      final r = context.read<Repository<Category, EntityQuery>>(); 
      widget.id == null ? await r.create(_cat!) : await r.update(widget.id!, _cat!); 
      if (mounted) context.pop(); 
    } on ValidationException catch (e) { 
      setState(() => _serverErrors = e.errors); 
      throw Exception('Validation'); 
    } on ApiException catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red)); 
      throw Exception('API'); 
    }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Новая категория' : 'Редактирование')), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24), 
        child: DynamicForm(
          serverErrors: _serverErrors, 
          onSave: _save, 
          fields: [
            FormFieldSpec(
              name: 'name', 
              label: 'Название', 
              type: FieldType.text, 
              initialValue: _cat!.name, 
              validator: (v) => (v == null || v.toString().trim().isEmpty) ? 'Обязательно' : null, 
              onSaved: (v) => _cat = Category(id: _cat!.id, name: v, deletedAt: _cat!.deletedAt)
            )
          ]
        )
      )
    );
  }
}