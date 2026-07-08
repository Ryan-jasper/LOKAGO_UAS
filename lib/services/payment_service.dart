import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = 'https://lokago-backend.vercel.app';

  Future<Map<String, dynamic>> createHeartTransaction({
    required String uid,
    required int amount,
    required int price,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/create-transaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'amount': amount, 'price': price}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal membuat transaksi: ${response.body}');
    }
    return jsonDecode(response.body);
  }
}