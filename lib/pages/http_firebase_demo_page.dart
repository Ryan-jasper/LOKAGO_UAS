import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/demo_api_service.dart';

class HttpFirebaseDemoPage extends StatefulWidget {
  const HttpFirebaseDemoPage({super.key});

  @override
  State<HttpFirebaseDemoPage> createState() => _HttpFirebaseDemoPageState();
}

class _HttpFirebaseDemoPageState extends State<HttpFirebaseDemoPage> {
  final DemoApiService service = DemoApiService();

  String resultText = 'Belum ada hasil';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    resultText = 'Page siap digunakan';
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> runAction(Future<dynamic> Function() action) async {
    setState(() {
      isLoading = true;
      resultText = 'Loading...';
    });

    try {
      final result = await action();
      setState(() {
        if (result is Map<String, dynamic>) {
          resultText = const JsonEncoder.withIndent('  ').convert(result);
        } else {
          resultText = result.toString();
        }
      });
    } catch (e) {
      setState(() {
        resultText = 'ERROR:\n$e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildActionButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F9D6C),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        title: const Text(
          'Demo HTTP & Firebase',
          style: TextStyle(
            color: Color(0xFF232248),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RAW HTTP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF232248),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              buildActionButton(
                text: 'HTTP GET',
                onTap: () => runAction(service.httpGetDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'HTTP POST',
                onTap: () => runAction(service.httpPostDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'HTTP PUT',
                onTap: () => runAction(service.httpPutDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'HTTP PATCH',
                onTap: () => runAction(service.httpPatchDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'HTTP DELETE',
                onTap: () => runAction(service.httpDeleteDemo),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FIREBASE REALTIME DATABASE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF232248),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              buildActionButton(
                text: 'Firebase GET',
                onTap: () => runAction(service.firebaseGetDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'Firebase POST',
                onTap: () => runAction(service.firebasePostDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'Firebase PATCH / UPDATE',
                onTap: () => runAction(service.firebasePatchDemo),
              ),
              const SizedBox(height: 10),
              buildActionButton(
                text: 'Firebase DELETE',
                onTap: () => runAction(service.firebaseDeleteDemo),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD9D4D6)),
                ),
                child: SelectableText(
                  resultText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF232248),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}