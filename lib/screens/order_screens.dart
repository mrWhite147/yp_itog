import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../state/list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_controls.dart';

class OrderListScreen extends StatefulWidget {
  final EntityQuery query;
  const OrderListScreen({super.key, required this.query});
  @override State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override void initState() { super.initState(); _load(); }
  @override void didUpdateWidget(covariant OrderListScreen oldWidget) { super.didUpdateWidget(oldWidget); if (widget.query != oldWidget.query) _load(); }
  void _load() => WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ListNotifier<Order, EntityQuery>>().load(widget.query));
  void _updateUrl(EntityQuery q) => context.go(Uri(path: '/orders', queryParameters: q.toMap()).toString());

  @override Widget build(BuildContext context) {
    final notifier = context.watch<ListNotifier<Order, EntityQuery>>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Менеджер заказов')),
      body: Column(children: [
        Expanded(child: notifier.status == LoadStatus.loading ? const Center(child: CircularProgressIndicator()) : EntityTable<Order>(
          items: notifier.result.items, idOf: (o) => o.id, isDeletedOf: (o) => false, selected: notifier.selected, 
          sortField: widget.query.sortField, sortAscending: widget.query.sortAscending,
          onSort: (f) => _updateUrl(EntityQuery(sortField: f, sortAscending: f == widget.query.sortField ? !widget.query.sortAscending : true, page: 1, size: widget.query.size)),
          columns: [
            TableColumnSpec(label: 'Номер заказа', sortField: 'id', build: (o) => Text('#${o.id}')), 
            TableColumnSpec(label: 'Сумма', sortField: 'totalAmount', build: (o) => Text('${o.totalAmount} ₽', style: const TextStyle(fontWeight: FontWeight.bold))), 
            TableColumnSpec(label: 'Статус', build: (o) => Chip(
              label: Text(o.status == 'new' ? 'Новый' : 'Завершен'),
              backgroundColor: o.status == 'new' ? Colors.orange.shade100 : Colors.green.shade100,
            )),
            TableColumnSpec(label: 'Дата', build: (o) => Text(o.createdAt.toLocal().toString().split('.')[0])),
          ],
        )),
        PaginationControls(page: notifier.result.page, totalPages: notifier.result.totalPages, totalItems: notifier.result.total, size: notifier.result.size, hasPrevious: notifier.result.hasPrevious, hasNext: notifier.result.hasNext, onPageChanged: (p) => _updateUrl(EntityQuery(page: p, size: widget.query.size, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending)), onSizeChanged: (s) => _updateUrl(EntityQuery(size: s, page: 1, search: widget.query.search, sortField: widget.query.sortField, sortAscending: widget.query.sortAscending))),
      ]),
    );
  }
}