import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
import 'murojaat_javob.dart';

class MurojaatTafsilotlari extends StatefulWidget {
  final ComplaintModel complaint;
  final bool isAdmin;
  const MurojaatTafsilotlari({required this.complaint, required this.isAdmin});

  @override
  _MurojaatTafsilotlariState createState() => _MurojaatTafsilotlariState();
}

class _MurojaatTafsilotlariState extends State<MurojaatTafsilotlari> {
  late ComplaintModel _complaint;
  UserModel? _studentInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    if (_complaint.studentId != 'anonymous') {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_complaint.studentId)
          .get();
      if (doc.exists) {
        _studentInfo = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(ComplaintStatus newStatus) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('murojaatlar').get();

    final list = snapshot.docs.map((doc) {
      return UserModel.fromJson(
        doc.data(),
    
      );
    }).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Holat yangilandi"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_complaint.title),
          backgroundColor:
              widget.isAdmin ? Colors.blue.shade700 : Colors.green.shade700,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_complaint.title),
        backgroundColor:
            widget.isAdmin ? Colors.blue.shade700 : Colors.green.shade700,
        actions: [
          if (widget.isAdmin && _complaint.status != ComplaintStatus.resolved)
            PopupMenuButton<ComplaintStatus>(
              onSelected: _updateStatus,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ComplaintStatus.pending,
                  child: Text("Kutilmoqda"),
                ),
                PopupMenuItem(
                  value: ComplaintStatus.reviewing,
                  child: Text("Ko'rib chiqilmoqda"),
                ),
                PopupMenuItem(
                  value: ComplaintStatus.resolved,
                  child: Text("Hal qilindi"),
                ),
              ],
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.more_vert),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradient(_complaint.status),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(_complaint.status),
                      color: _getStatusColor(_complaint.status),
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Holat",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _getStatusText(_complaint.status),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Complaint Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Murojaat ma'lumotlari",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _infoRow(
                      Icons.category,
                      "Kategoriya",
                      _complaint.category,
                      _getCategoryColor(_complaint.category),
                    ),
                    _infoRow(
                      Icons.access_time,
                      "Yuborilgan vaqt",
                      _formatDateTime(_complaint.createdAt),
                      Colors.grey,
                    ),
                    if (_complaint.updatedAt != null)
                      _infoRow(
                        Icons.update,
                        "Yangilangan vaqt",
                        _formatDateTime(_complaint.updatedAt!),
                        Colors.grey,
                      ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      "Batafsil:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _complaint.description,
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Student Info (if not anonymous)
            if (_studentInfo != null) ...[
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Talaba ma'lumotlari",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _infoRow(
                        Icons.person,
                        "FIO",
                        _studentInfo!.fullName,
                        Colors.blue,
                      ),
                      _infoRow(
                        Icons.email,
                        "Email",
                        _studentInfo!.email,
                        Colors.blue,
                      ),
                      _infoRow(
                        Icons.phone,
                        "Telefon",
                        _studentInfo!.phoneNumber,
                        Colors.blue,
                      ),
                      if (_studentInfo!.studentId != null)
                        _infoRow(
                          Icons.school,
                          "Talaba ID",
                          _studentInfo!.studentId!,
                          Colors.blue,
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Response
            if (_complaint.response != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, color: Colors.green.shade700),
                        SizedBox(width: 8),
                        Text(
                          "Javob",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(_complaint.response!),
                    SizedBox(height: 8),
                    if (_complaint.updatedAt != null)
                      Text(
                        _formatDateTime(_complaint.updatedAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24),

            // Action Buttons
            if (widget.isAdmin && _complaint.status != ComplaintStatus.resolved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MurojaatJavob(complaint: _complaint),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _complaint = result;
                      });
                    }
                  },
                  icon: Icon(Icons.reply),
                  label: Text("Javob berish"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 32, child: Icon(icon, size: 20, color: color)),
          SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.reviewing:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  List<Color> _getStatusGradient(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return [Colors.orange.shade400, Colors.orange.shade700];
      case ComplaintStatus.reviewing:
        return [Colors.blue.shade400, Colors.blue.shade700];
      case ComplaintStatus.resolved:
        return [Colors.green.shade400, Colors.green.shade700];
      case ComplaintStatus.closed:
        return [Colors.grey.shade400, Colors.grey.shade700];
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.pending;
      case ComplaintStatus.reviewing:
        return Icons.visibility;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.closed:
        return Icons.lock;
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
        return Colors.red;
      case 'Ijtimoiy':
        return Colors.orange;
      case 'Moliyaviy':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
