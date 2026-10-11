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

class ManufacturerListScreen extends StatefulWidget {
  final ManufacturerQuery query;
  const ManufacturerListScreen({super.key, required this.query});
  @override State<ManufacturerListScreen> createState() => _ManufacturerListScreenState();
}

class _ManufacturerListScreenState extends State<ManufacturerListScreen> {
  @override void initState() { super.initState(); _load(); }
  @override void didUpdateWidget(covariant ManufacturerListScreen oldWidget) { super.didUpdateWidget(oldWidget); if (widget.query != oldWidget.query) _load(); }
  void _load() => WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ListNotifier<Manufacturer, ManufacturerQuery>>().load(widget.query));
  void _updateUrl(ManufacturerQuery q) => context.go(Uri(path: '/manufacturers', queryParameters: q.toMap()).toString());

  @override Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Manufacturer, ManufacturerQuery>>();
    final auth = context.watch<AuthNotifier>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Производители'), actions: [
        if (auth.hasRole(Role.manager)) 
          FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Создать'), onPressed: () => context.push('/manufacturers/new')), 
        const SizedBox(width: 16)
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: 250, child: DebouncedSearch(initialValue: widget.query.search, onChanged: (v) => _updateUrl(ManufacturerQuery(search: v, page: 1, size: widget.query.size)))),
          SizedBox(width: 200, child: CheckboxListTile(title: const Text('С удаленными'), value: widget.query.includeDeleted, onChanged: (v) => _updateUrl(ManufacturerQuery(includeDeleted: v ?? false, page: 1)), controlAffinity: ListTileControlAffinity.leading)),
        ])),
        if (notifier.hasSelection && auth.hasRole(Role.manager)) 
          Container(color: Colors.blue.shade50, padding: const EdgeInsets.all(8), child: Row(children: [Text('Выбрано: ${notifier.selected.length}'), const Spacer(), FilledButton(onPressed: () => notifier.deleteSelected(widget.query), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Удалить'))])),
        Expanded(child: notifier.status == LoadStatus.loading ? const Center(child: CircularProgressIndicator()) : EntityTable<Manufacturer>(
          items: notifier.result.items, idOf: (m) => m.id, isDeletedOf: (m) => m.isDeleted, selected: notifier.selected, 
          onToggleSelect: auth.hasRole(Role.manager) ? notifier.toggleSelection : null, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending,
          onSort: (f) => _updateUrl(ManufacturerQuery(sortField: f, sortAscending: f == widget.query.sortField ? !widget.query.sortAscending : true, page: 1, size: widget.query.size)),
          columns: [TableColumnSpec(label: 'Название', sortField: 'name', build: (m) => Text(m.name)), TableColumnSpec(label: 'Страна', sortField: 'country', build: (m) => Text(m.country)), TableColumnSpec(label: 'Год основания', sortField: 'foundedYear', build: (m) => Text('${m.foundedYear}'))],
          actions: (m) => [
            if (auth.hasRole(Role.manager)) IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/manufacturers/${m.id}/edit')), 
            if (m.isDeleted && auth.hasRole(Role.admin)) IconButton(icon: const Icon(Icons.restore), onPressed: () => notifier.restore(m.id, widget.query))
          ],
        )),
        PaginationControls(page: notifier.result.page, totalPages: notifier.result.totalPages, totalItems: notifier.result.total, size: notifier.result.size, hasPrevious: notifier.result.hasPrevious, hasNext: notifier.result.hasNext, onPageChanged: (p) => _updateUrl(ManufacturerQuery(page: p, size: widget.query.size, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending)), onSizeChanged: (s) => _updateUrl(ManufacturerQuery(size: s, page: 1, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending))),
      ]),
    );
  }
}

class ManufacturerFormScreen extends StatefulWidget {
  final String? id; const ManufacturerFormScreen({super.key, this.id});
  @override State<ManufacturerFormScreen> createState() => _ManufacturerFormScreenState();
}
class _ManufacturerFormScreenState extends State<ManufacturerFormScreen> {
  Manufacturer? _man; Map<String, String> _serverErrors = {}; bool _isLoading = true;
  @override void initState() { super.initState(); _load(); }
  
  Future<void> _load() async {
    if (widget.id == null) { setState(() { _man = const Manufacturer(id: '', name: '', foundedYear: 0, country: ''); _isLoading = false; }); return; }
    try { 
      final m = await context.read<Repository<Manufacturer, ManufacturerQuery>>().findById(widget.id!); 
      setState(() { _man = m; _isLoading = false; }); 
    } catch (e) { 
      if (!mounted) return;
      context.pop(); 
    }
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    try {
      final r = context.read<Repository<Manufacturer, ManufacturerQuery>>();
      widget.id == null ? await r.create(_man!) : await r.update(widget.id!, _man!);
      if (mounted) context.pop();
    } on ValidationException catch (e) { setState(() => _serverErrors = e.errors); throw Exception('Validation'); } 
    on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red)); throw Exception('API'); }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Новый производитель' : 'Редактирование')), 
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: DynamicForm(serverErrors: _serverErrors, onSave: _save, fields: [
        FormFieldSpec(name: 'name', label: 'Название компании', type: FieldType.text, initialValue: _man!.name, validator: (v) => (v == null || v.toString().trim().isEmpty) ? 'Обязательно' : null, onSaved: (v) => _man = _man!.copyWith(name: v)),
        FormFieldSpec(name: 'country', label: 'Страна', type: FieldType.text, initialValue: _man!.country, onSaved: (v) => _man = _man!.copyWith(country: v)),
        FormFieldSpec(name: 'foundedYear', label: 'Год основания', type: FieldType.number, initialValue: _man!.foundedYear, onSaved: (v) => _man = _man!.copyWith(foundedYear: int.tryParse(v) ?? 0)),
      ])),
    );
  }
}