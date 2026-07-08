import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HeartPaymentPage extends StatefulWidget {
  final String redirectUrl;

  const HeartPaymentPage({super.key, required this.redirectUrl});

  @override
  State<HeartPaymentPage> createState() => _HeartPaymentPageState();
}

class _HeartPaymentPageState extends State<HeartPaymentPage> {
  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color textDark = Color(0xFF232248);

  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;

            // Midtrans akan redirect ke URL yang mengandung kata ini
            // setelah pembayaran selesai (baik sukses, pending, maupun gagal).
            final isFinishRedirect = url.contains('finish') ||
                url.contains('success') ||
                url.contains('unfinish') ||
                url.contains('error');

            if (isFinishRedirect) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Pembayaran',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: textDark),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F9D6C)),
            ),
        ],
      ),
    );
  }
}