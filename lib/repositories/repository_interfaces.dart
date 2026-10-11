import '../models/page_result.dart';
import '../models/queries.dart';

abstract interface class Repository<T, Q extends BaseQuery> {
  Future<PageResult<T>> find(Q query);
  Future<T> findById(String id);
  Future<T> create(T item);  
  Future<T> update(String id, T item);  
  Future<void> softDelete(String id);  
  Future<void> hardDelete(String id);  
  Future<void> restore(String id);  
  Future<int> deleteMany(List<String> ids, {bool hard = false});
}