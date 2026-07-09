import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/payment_service.dart';
import 'heart_payment.dart';

class HeartPackage {
  final int hearts;
  final int price; // dalam Rupiah

  const HeartPackage({required this.hearts, required this.price});
}

class HeartStorePage extends StatefulWidget {
  const HeartStorePage({super.key});

  @override
  State<HeartStorePage> createState() => _HeartStorePageState();
}

class _HeartStorePageState extends State<HeartStorePage> {
  static const Color bgColor = Color(0xFFF4F4F4);
  static const Color darkText = Color(0xFF232248);
  static const Color greenMain = Color(0xFF0F9D6C);
  static const Color greenShadow = Color(0xFF6CC1A8);
  static const Color borderColor = Color(0xFFBFC2E2);
  static const Color mutedText = Color(0xFF9A9A9A);

  static const List<HeartPackage> packages = [
    HeartPackage(hearts: 5, price: 5000),
    HeartPackage(hearts: 10, price: 10000),
    HeartPackage(hearts: 15, price: 12500),
  ];

  bool isProcessing = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  String formatRupiah(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return 'Rp$buffer';
  }

  Future<void> handleBuy(HeartPackage package) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final result = await PaymentService().createHeartTransaction(
        uid: uid,
        amount: package.hearts,
        price: package.price,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HeartPaymentPage(redirectUrl: result['redirectUrl']),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menunggu konfirmasi pembayaran... Saldo hearts akan otomatis bertambah begitu pembayaran terverifikasi.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai pembayaran: $e')),
      );
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Widget buildHeartsBalance() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        int hearts = 0;
        int maxHearts = 15;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          hearts = (data?['hearts'] ?? 0) as int;
          maxHearts = (data?['maxHearts'] ?? 15) as int;
          hearts = hearts.clamp(0, maxHearts).toInt();
        }

        final isEmpty = hearts <= 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.065),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isEmpty
                    ? const Color(0xFFFFE8E4)
                    : const Color(0xFFFFF0EC),
                child: Icon(
                  isEmpty ? Icons.favorite_border_rounded : Icons.favorite_rounded,
                  color: const Color(0xFFD6372A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? '-/-' : '$hearts/$maxHearts',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEmpty ? 'Heart habis, yuk isi lagi' : 'Heart tersedia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isEmpty ? const Color(0xFFD6372A) : mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPackageCard(HeartPackage package) {
    final isGold = package.hearts == 15;
 
    final iconColor = isGold ? const Color(0xFFF4B11A) : const Color(0xFFD6372A);
    final iconBgColor = isGold ? const Color(0xFFFFF6DA) : const Color(0xFFFCEBEA);
 
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.favorite_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${package.hearts} Hearts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(package.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isProcessing ? null : () => handleBuy(package),
            style: ElevatedButton.styleFrom(
              backgroundColor: greenMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'BELI',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Toko Hearts',
          style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildHeartsBalance(),
              const SizedBox(height: 24),
              const Text(
                'Pilih Paket',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 14),
              ...packages.map(buildPackageCard),
            ],
          ),
        ),
      ),
    );
  }
}