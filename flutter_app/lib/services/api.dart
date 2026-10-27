import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// Deployed Render backend URL
const String baseUrl = 'https://grocery-scanner-api-2iq2.onrender.com';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class Api {
  static String? token;

  static Future<void> loadToken() async {
    token = (await SharedPreferences.getInstance()).getString('token');
  }

  static Future<void> saveToken(String? t) async {
    token = t;
    final p = await SharedPreferences.getInstance();
    t == null ? await p.remove('token') : await p.setString('token', t);
  }

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _handle(http.Response r) {
    final body = r.body.isNotEmpty ? jsonDecode(r.body) : null;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body is Map && body['detail'] != null ? body['detail'].toString() : 'Error ${r.statusCode}';
    throw ApiException(r.statusCode, msg);
  }

  static Future<void> login(String email, String password) async {
    final r = await http.post(Uri.parse('$baseUrl/auth/login'), headers: _h, body: jsonEncode({'email': email, 'password': password}));
    await saveToken(_handle(r)['access_token']);
  }

  static Future<void> register(String name, String email, String password, bool diabetic) async {
    final r = await http.post(Uri.parse('$baseUrl/auth/register'),
        headers: _h, body: jsonEncode({'name': name, 'email': email, 'password': password, 'is_diabetic': diabetic}));
    await saveToken(_handle(r)['access_token']);
  }

  static Future<UserProfile> me() async =>
      UserProfile.fromJson(_handle(await http.get(Uri.parse('$baseUrl/me'), headers: _h)));

  static Future<UserProfile> updateMe({String? name, bool? diabetic}) async {
    final r = await http.patch(Uri.parse('$baseUrl/me'),
        headers: _h, body: jsonEncode({if (name != null) 'name': name, if (diabetic != null) 'is_diabetic': diabetic}));
    return UserProfile.fromJson(_handle(r));
  }

  static Future<Product> product(String barcode) async =>
      Product.fromJson(_handle(await http.get(Uri.parse('$baseUrl/products/$barcode'), headers: _h)));

  static Future<List<HistoryItem>> history() async {
    final l = _handle(await http.get(Uri.parse('$baseUrl/history'), headers: _h)) as List;
    return l.map((e) => HistoryItem.fromJson(e)).toList();
  }

  static Future<List<TrendPoint>> trends() async {
    final l = _handle(await http.get(Uri.parse('$baseUrl/trends'), headers: _h)) as List;
    return l.map((e) => TrendPoint(e['date'], (e['avg_score'] as num).toDouble())).toList();
  }

  static Future<Map<String, dynamic>> createOrder() async =>
      Map<String, dynamic>.from(_handle(await http.post(Uri.parse('$baseUrl/subscription/order'), headers: _h)));

  static Future<UserProfile> verifyPayment(String orderId, String paymentId, String signature) async {
    final r = await http.post(Uri.parse('$baseUrl/subscription/verify'),
        headers: _h, body: jsonEncode({'order_id': orderId, 'payment_id': paymentId, 'signature': signature}));
    return UserProfile.fromJson(_handle(r));
  }

  /// DEV ONLY - remove before release
  static Future<UserProfile> devActivate() async =>
      UserProfile.fromJson(_handle(await http.post(Uri.parse('$baseUrl/subscription/dev-activate'), headers: _h)));
}
