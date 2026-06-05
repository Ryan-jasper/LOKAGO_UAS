import 'dart:convert';
import 'package:http/http.dart' as http;

class DemoApiService {

  Future<Map<String, dynamic>> httpGetDemo() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('HTTP GET gagal: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> httpPostDemo() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Lokago Demo',
        'body': 'Belajar bahasa daerah',
        'userId': 1,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('HTTP POST gagal: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> httpPutDemo() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': 1,
        'title': 'Lokago PUT',
        'body': 'Update penuh data',
        'userId': 1,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('HTTP PUT gagal: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> httpPatchDemo() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Lokago PATCH',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('HTTP PATCH gagal: ${response.statusCode}');
  }

  Future<String> httpDeleteDemo() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return 'HTTP DELETE berhasil';
    }
    throw Exception('HTTP DELETE gagal: ${response.statusCode}');
  }

  static const String realtimeDbBaseUrl =
      'https://YOUR_PROJECT_ID-default-rtdb.asia-southeast1.firebasedatabase.app';

  Future<Map<String, dynamic>> firebaseGetDemo() async {
    final url = Uri.parse('$realtimeDbBaseUrl/demo.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = response.body;
      if (body == 'null') {
        return {'message': 'Belum ada data di Realtime Database'};
      }
      return jsonDecode(body);
    }
    throw Exception('Firebase GET gagal: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> firebasePostDemo() async {
    final url = Uri.parse('$realtimeDbBaseUrl/demo.json');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Lokago Firebase POST',
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Firebase POST gagal: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> firebasePatchDemo() async {
    final url = Uri.parse('$realtimeDbBaseUrl/demo/sample.json');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Lokago Firebase PATCH',
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Firebase PATCH gagal: ${response.statusCode}');
  }

  Future<String> firebaseDeleteDemo() async {
    final url = Uri.parse('$realtimeDbBaseUrl/demo/sample.json');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return 'Firebase DELETE berhasil';
    }
    throw Exception('Firebase DELETE gagal: ${response.statusCode}');
  }
}