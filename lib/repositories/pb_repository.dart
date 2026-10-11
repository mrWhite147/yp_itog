import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/queries.dart';
import 'repository_interfaces.dart';

class PbRepository<T, Q extends BaseQuery> implements Repository<T, Q> {
  final Dio _dio;
  final String collection;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  CancelToken? _cancelToken;

  PbRepository(this._dio, this.collection, this.fromJson, this.toJson);

  String get path => '/collections/$collection/records';

  @override
  Future<PageResult<T>> find(Q q) async {
    _cancelToken?.cancel('Новый запрос перекрыл старый');
    _cancelToken = CancelToken();

    return guard(() async {
      final pbParams = <String, dynamic>{
        'page': q.page,
        'perPage': q.size,
        'sort': '${q.sortAscending ? '+' : '-'}${q.sortField}',
      };
      List<String> filters = [];      
      if (!q.includeDeleted) filters.add('deletedAt = ""');
      
      if (q.search.isNotEmpty) {
        filters.add('(name ~ "${q.search}" || id = "${q.search}")');
      }

      if (q is ProductQuery) {
        if (q.categoryId != null) filters.add('categoryIds ~ "${q.categoryId}"');
        if (q.manufacturerId != null) filters.add('manufacturerId = "${q.manufacturerId}"');
        if (q.priceFrom != null) filters.add('price >= ${q.priceFrom}');
        if (q.priceTo != null) filters.add('price <= ${q.priceTo}');
        if (q.stockMax != null) filters.add('stockCount <= ${q.stockMax}');
      }

      if (filters.isNotEmpty) {
        pbParams['filter'] = filters.join(' && ');
      }

      final res = await _dio.get(path, queryParameters: pbParams, cancelToken: _cancelToken);
      final data = res.data as Map<String, dynamic>;

      return PageResult<T>(
        items: (data['items'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
        page: data['page'] ?? 1,
        size: data['perPage'] ?? 10,
        total: data['totalItems'] ?? 0,
      );
    });
  }

  @override
  Future<T> findById(String id) => guard(() async {
    final res = await _dio.get('$path/$id');
    return fromJson(res.data);
  });

  @override
  Future<T> create(T item) => guard(() async {
    final res = await _dio.post(path, data: toJson(item));
    return fromJson(res.data);
  });

  @override
  Future<T> update(String id, T item) => guard(() async {
    final res = await _dio.patch('$path/$id', data: toJson(item)); 
    return fromJson(res.data);
  });

  @override
  Future<void> softDelete(String id) => guard(() async {
    await _dio.patch('$path/$id', data: {'deletedAt': DateTime.now().toIso8601String()});
  });

  @override
  Future<void> hardDelete(String id) => guard(() async {
    await _dio.delete('$path/$id');
  });

  @override
  Future<void> restore(String id) => guard(() async {
    await _dio.patch('$path/$id', data: {'deletedAt': ''});
  });

  @override
  Future<int> deleteMany(List<String> ids, {bool hard = false}) => guard(() async {
    int count = 0;
    for (final id in ids) {
      if (hard) {
        await _dio.delete('$path/$id');
      } else {
        await _dio.patch('$path/$id', data: {'deletedAt': DateTime.now().toIso8601String()});
      }
      count++;
    }
    return count;
  });
}