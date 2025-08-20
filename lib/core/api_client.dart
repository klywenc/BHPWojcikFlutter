import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String base;
  ApiClient(this.base);

  static const _tokenKey = 'jakis-token';

  Future<void> _saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tokenKey, token);
  }

  Future<String?> _readToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_tokenKey);
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
  }

  Future<(bool, String)> checkServer() async {
    try {
      final res = await http
          .get(Uri.parse('$base/hello'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (true, 'HTTP ${res.statusCode}');
      }
      return (false, 'HTTP ${res.statusCode} ${res.reasonPhrase}');
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String)> register({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$base/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'registrationCode': registrationCode,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (true, 'OK');
      }
      return (false, 'HTTP ${res.statusCode}: ${res.body}');
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String)> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$base/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final token = (map['accessToken'] ?? '').toString();
        if (token.isNotEmpty) {
          await _saveToken(token);
        }
        return (true, res.body);
      }
      return (false, 'HTTP ${res.statusCode}: ${res.body}');
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String)> createIncident({
    required String description,
    required int departmentId,
    required int categoryId,
    required List<File> photos,
  }) async {
    try {
      final token = await _readToken();

      final uri = Uri.parse('$base/api/incidents');
      final req = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }

      final incidentJson = jsonEncode({
        'description': description,
        'departmentId': departmentId,
        'categoryId': categoryId,
      });

      req.files.add(http.MultipartFile.fromString(
        'incident',
        incidentJson,
        contentType: MediaType('application', 'json'),
        filename: 'incident.json',
      ));

      for (final f in photos) {
        req.files.add(await http.MultipartFile.fromPath(
          'files',
          f.path,
          filename: f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : 'photo.jpg',
        ));
      }

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (true, res.body);
      }
      return (false, 'HTTP ${res.statusCode}: ${res.body}');
    } catch (e) {
      return (false, e.toString());
    }
  }
}
