import 'package:dio/dio.dart';

class ApiClient {
  final String baseUrl;
  final Dio _dio;

  ApiClient(this.baseUrl)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (_) => true,
        ));

  Future<(bool ok, String msg)> checkServer() async {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      final r = await _dio.get('$base/actuator/health');
      if (r.statusCode == 200 && r.data.toString().contains('UP')) {
        return (true, 'UP');
      }
    } catch (_) {}
    try {
      final r = await _dio.get('$base/hello');
      if (r.statusCode == 200) return (true, '/hello OK');
      return (false, 'HTTP ${r.statusCode} na /hello');
    } on DioException catch (e) {
      return (false, e.message ?? 'Błąd połączenia');
    }
  }
}
