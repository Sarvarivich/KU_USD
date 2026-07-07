import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/file.opener.dart';

// ─── Creative LIGHT palette ───
class _LC {
  static const bg = Color(0xFFF3F1FB);
  static const card = Colors.white;
  static const purple = Color(0xFF6C5CE7);
  static const violet = Color(0xFFA29BFE);
  static const teal = Color(0xFF00CEC9);
  static const mint = Color(0xFF55EFC4);
  static const pink = Color(0xFFFD79A8);
  static const orange = Color(0xFFFDCB6E);
  static const coral = Color(0xFFE17055);
  static const ink = Color(0xFF2D2A4A);
  static const muted = Color(0xFF8B86A8);
  static const faint = Color(0xFFE9E5FA);
}

class TolovCheklariScreen extends StatefulWidget {
  /// Tab sifatida ishlatilganda (push qilinmagan bo'lsa ham) orqaga
  /// qaytish tugmasi bosilganda chaqiriladigan callback.
  final VoidCallback? onBack;

  const TolovCheklariScreen({super.key, this.onBack});

  @override
  State<TolovCheklariScreen> createState() => _TolovCheklariScreenState();
}

class _TolovCheklariScreenState extends State<TolovCheklariScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve(
      String docId, String studentId, String studentName) async {
    await FirebaseFirestore.instance
        .collection('payment_checks')
        .doc(docId)
        .update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewNote': null,
    });
    await _notifyStudent(
      studentId: studentId,
      title: 'To\'lov cheki tasdiqlandi ✓',
      body: 'Siz yuborgan to\'lov cheki admin tomonidan tasdiqlandi.',
      checkId: docId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$studentName cheki tasdiqlandi'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _showRejectDialog(
      String docId, String studentId, String studentName) async {
    _noteCtrl.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Bekor qilish'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$studentName ning cheki bekor qilinadi.'),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Sabab (ixtiyoriy)',
                hintText: 'Masalan: chek rasmiy emas, summa xato...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Orqaga'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
            label: const Text('Bekor qilish',
                style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('payment_checks')
                  .doc(docId)
                  .update({
                'status': 'rejected',
                'reviewedAt': FieldValue.serverTimestamp(),
                'reviewNote': _noteCtrl.text.trim(),
              });
              await _notifyStudent(
                studentId: studentId,
                title: 'To\'lov cheki rad etildi ✗',
                body: _noteCtrl.text.trim().isNotEmpty
                    ? 'Chekingiz rad etildi. Sabab: ${_noteCtrl.text.trim()}'
                    : 'Siz yuborgan to\'lov cheki rad etildi. Iltimos, qayta yuboring.',
                checkId: docId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$studentName cheki rad etildi'),
                      backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _notifyStudent({
    required String studentId,
    required String title,
    required String body,
    required String checkId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': studentId,
      'title': title,
      'body': body,
      'type': 'payment_check_result',
      'checkId': checkId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Fayl endi Firebase Storage'da emas, Firestore hujjatida base64
  // matn sifatida saqlanadi. Platformaga qarab (web yoki mobil/desktop)
  // to'g'ri usulda ochiladi/yuklab olinadi (file_opener.dart orqali).
  Future<void> _downloadCheck(String fileBase64, String fileName) async {
    try {
      final bytes = base64Decode(fileBase64);
      final error = await openOrDownloadFile(bytes, fileName);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Faylni ochishda xatolik: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LC.bg,
      appBar: AppBar(
        title: const Text("To'lov cheklari",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_LC.purple, _LC.violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        // ✅ Orqaga qaytish tugmasi har doim ko'rinadi (tab sifatida ham,
        // push qilingan sahifa sifatida ham ishlatilganda)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Orqaga',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              widget.onBack?.call();
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kutilmoqda'),
                  SizedBox(width: 4),
                  _PendingBadge(),
                ],
              ),
            ),
            Tab(text: 'Tasdiqlangan'),
            Tab(text: 'Rad etilgan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('pending'),
          _buildList('approved'),
          _buildList('rejected'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payment_checks')
          .where('status', isEqualTo: status)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // ✅ Avval xatolikni tekshiramiz — aks holda Firestore so'rovi
        // (masalan, kerakli composite index yo'qligi sababli) xatolik
        // bersa, ekran "cheklar yo'q" deb ko'rsatib, chekni yashirib
        // qo'yardi. Endi xatolik aniq ko'rsatiladi.
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 56, color: _LC.coral),
                  const SizedBox(height: 12),
                  Text(
                    "Cheklarni yuklashda xatolik: ${snap.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _LC.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Agar xabarda 'index' so'zi bo'lsa, Firebase konsolida "
                    "havolani ochib composite index yarating.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _LC.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.hourglass_empty
                      : status == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'pending'
                      ? "Kutilayotgan cheklar yo'q"
                      : status == 'approved'
                          ? "Tasdiqlangan cheklar yo'q"
                          : "Rad etilgan cheklar yo'q",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return _buildCheckCard(doc.id, d, status);
          },
        );
      },
    );
  }

  Widget _buildCheckCard(String docId, Map<String, dynamic> d, String status) {
    final studentName = (d['studentName'] ?? 'Noma\'lum talaba') as String;
    final fileName = (d['fileName'] ?? 'fayl') as String;
    final fileType = (d['fileType'] ?? 'pdf') as String;
    final fileBase64 = (d['fileBase64'] ?? '') as String;
    final isPdf = fileType.toLowerCase() == 'pdf';
    final isImage =
        ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(fileType.toLowerCase());

    final ts = d['uploadedAt'];
    String dateStr = '—';
    if (ts != null) {
      try {
        final dt = (ts as dynamic).toDate() as DateTime;
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final statusColor = status == 'approved'
        ? _LC.teal
        : status == 'rejected'
            ? _LC.coral
            : _LC.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _LC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _LC.faint),
        boxShadow: [
          BoxShadow(
            color: _LC.purple.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_LC.purple, _LC.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _LC.ink)),
                      Text(dateStr,
                          style:
                              const TextStyle(fontSize: 12, color: _LC.muted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status == 'approved'
                        ? 'Tasdiqlandi'
                        : status == 'rejected'
                            ? 'Rad etildi'
                            : 'Kutilmoqda',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 💰 To'lov sanasi va summasi — talaba kiritgan ma'lumotlar
            if (d['paymentDate'] != null || d['amount'] != null) ...[
              Row(
                children: [
                  if (d['paymentDate'] != null)
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.event_rounded,
                        label: "To'lov sanasi",
                        value: () {
                          try {
                            final dt = (d['paymentDate'] as dynamic).toDate()
                                as DateTime;
                            return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
                          } catch (_) {
                            return '—';
                          }
                        }(),
                      ),
                    ),
                  if (d['paymentDate'] != null && d['amount'] != null)
                    const SizedBox(width: 10),
                  if (d['amount'] != null)
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.payments_rounded,
                        label: "To'lov summasi",
                        value: "${d['amount']} so'm",
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (isImage && fileBase64.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(fileBase64),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: _LC.bg,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        color: _LC.muted),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _LC.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _LC.faint),
              ),
              child: Row(
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: isPdf ? _LC.coral : _LC.purple,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _LC.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (fileBase64.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _LC.purple,
                    side: BorderSide(color: _LC.purple.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.file_download_rounded, size: 18),
                  label: const Text(
                    'Chekni yuklab olish',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _downloadCheck(fileBase64, fileName),
                ),
              ),
            ],
            if (status == 'rejected' &&
                d['reviewNote'] != null &&
                (d['reviewNote'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _LC.coral.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: _LC.coral, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Sabab: ${d['reviewNote']}",
                        style: TextStyle(
                            fontSize: 12, color: _LC.coral.withOpacity(0.9)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LC.coral,
                        side: BorderSide(color: _LC.coral.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Rad etish'),
                      onPressed: () => _showRejectDialog(
                          docId, d['studentId'] as String, studentName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LC.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18, color: Colors.white),
                      label: const Text('Tasdiqlash',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      onPressed: () => _approve(
                          docId, d['studentId'] as String, studentName),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Kutilmoqda tab uchun real-time badge
class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payment_checks')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _LC.coral,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

// Talaba kiritgan to'lov sanasi / summasi kabi ma'lumotlarni ko'rsatish uchun chip
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _LC.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LC.faint),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _LC.purple),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9.5, color: _LC.muted),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _LC.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
