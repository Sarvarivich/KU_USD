import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import 'murojaat_tafsilotlari.dart';
import 'murojaat_yozish.dart';

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

class MurojaatlarList extends StatelessWidget {
  final bool isAdmin;
  final String? studentId;
  const MurojaatlarList({super.key, required this.isAdmin, this.studentId});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('complaints');

    if (!isAdmin && studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }

    return Scaffold(
      backgroundColor: _LC.bg,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isAdmin ? "Barcha murojaatlar" : "Mening murojaatlarim",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_LC.purple, _LC.violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (value) {},
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'all', child: Text("Barcha")),
                PopupMenuItem(value: 'pending', child: Text("Kutilmoqda")),
                PopupMenuItem(
                    value: 'reviewing', child: Text("Ko'rib chiqilmoqda")),
                PopupMenuItem(value: 'resolved', child: Text("Hal qilingan")),
              ],
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: _LC.coral),
                  const SizedBox(height: 16),
                  Text("Xatolik: ${snapshot.error}",
                      style: const TextStyle(color: _LC.muted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _LC.purple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text("Qayta urunish",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _LC.purple));
          }

          var complaints = snapshot.data!.docs;
          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    size: 72,
                    color: _LC.muted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Murojaatlar yo'q",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _LC.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAdmin
                        ? "Hali hech qanday murojaat yozilmagan"
                        : "Siz hali murojaat yozmagansiz",
                    style: const TextStyle(color: _LC.muted),
                  ),
                  if (!isAdmin && studentId != null) ...[
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MurojaatYozish(
                              studentId: studentId!,
                              studentName: "",
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Murojaat yozish"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LC.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var complaint = ComplaintModel.fromJson(
                  complaints[index].data() as Map<String, dynamic>);
              return _buildComplaintCard(context, complaint, isAdmin);
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(
      BuildContext context, ComplaintModel complaint, bool isAdmin) {
    final statusColor = _getStatusColor(complaint.status);
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MurojaatTafsilotlari(
                  complaint: complaint,
                  isAdmin: isAdmin,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getStatusIcon(complaint.status),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _LC.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _LC.muted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(complaint.category),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              complaint.category,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(complaint.status),
                              style: TextStyle(
                                fontSize: 9.5,
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(complaint.createdAt),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _LC.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _LC.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return _LC.orange;
      case ComplaintStatus.reviewing:
        return _LC.purple;
      case ComplaintStatus.resolved:
        return _LC.teal;
      case ComplaintStatus.closed:
        return _LC.muted;
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.pending_rounded;
      case ComplaintStatus.reviewing:
        return Icons.visibility_rounded;
      case ComplaintStatus.resolved:
        return Icons.check_circle_rounded;
      case ComplaintStatus.closed:
        return Icons.lock_rounded;
    }
  }

  String _getStatusText(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return "Kutilmoqda";
      case ComplaintStatus.reviewing:
        return "Ko'rib chiqilmoqda";
      case ComplaintStatus.resolved:
        return "Hal qilindi";
      case ComplaintStatus.closed:
        return "Yopilgan";
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Texnik':
        return _LC.coral;
      case 'Ijtimoiy':
        return _LC.orange;
      case 'Moliyaviy':
        return _LC.violet;
      default:
        return _LC.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return "${difference.inDays} kun oldin";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} soat oldin";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minut oldin";
    } else {
      return "Hozirgina";
    }
  }
}
