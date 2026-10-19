import '../../../../core/network/api_client.dart';
import '../models/spark_model.dart';

abstract class SparksRepository {
  Future<List<SparkModel>> getDailySparks();
  Future<void> connect(String userId);
  Future<void> pass(String userId);
  Future<void> save(String userId);
}

class SparksRepositoryImpl implements SparksRepository {
  @override
  Future<List<SparkModel>> getDailySparks() async {
    try {
      final res = await ApiClient.instance.get('/match/sparks');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List;
        return list.map((item) => SparkModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> connect(String userId) async {
    try {
      await ApiClient.instance.post('/match/connect', data: {'target_user_id': userId});
    } catch (_) {}
  }

  @override
  Future<void> pass(String userId) async {
    try {
      await ApiClient.instance.post('/match/pass', data: {'target_user_id': userId});
    } catch (_) {}
  }

  @override
  Future<void> save(String userId) async {
    try {
      await ApiClient.instance.post('/match/save', data: {'target_user_id': userId});
    } catch (_) {}
  }
}
