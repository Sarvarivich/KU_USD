import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class MurojaatYozish extends StatefulWidget {
  final String studentId;
  final String studentName;
  const MurojaatYozish({
    required this.studentId,
    required this.studentName,
  });

  @override
  _MurojaatYozishState createState() => _MurojaatYozishState();
}

class _MurojaatYozishState extends State<MurojaatYozish> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Umumiy';
  bool _isAnonymous = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Texnik',
    'Ijtimoiy',
    'Moliyaviy',
    'Umumiy'
  ];

  final Map<String, IconData> _categoryIcons = {
    'Texnik': Icons.build,
    'Ijtimoiy': Icons.people,
    'Moliyaviy': Icons.attach_money,
    'Umumiy': Icons.info,
  };

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      ComplaintModel newComplaint = ComplaintModel(
        id: '',
        studentId: _isAnonymous ? 'anonymous' : widget.studentId,
        title: _titleController.text,
        description: _descController.text,
        category: _selectedCategory,
        status: ComplaintStatus.pending,
        priority: ComplaintPriority.medium,
        createdAt: DateTime.now(),
        attachments: [],
      );

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('complaints')
          .add(newComplaint.toJson());
      await docRef.update({'id': docRef.id});

      // Admin uchun Firestore notification yozish
      final name = _isAnonymous ? 'Anonim foydalanuvchi' : widget.studentName;
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'new_complaint',
        'title': '📩 Yangi murojaat',
        'body': '$name: ${_titleController.text}',
        'category': _selectedCategory,
        'complaintId': docRef.id,
        'studentId': _isAnonymous ? 'anonymous' : widget.studentId,
        'studentName': name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'targetRole': 'admin',
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Murojaat yuborildi"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yangi murojaat"),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Category Selection
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
                        "Murojaat turi",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          bool isSelected = _selectedCategory == category;
                          return FilterChip(
                            label: Text(category),
                            avatar: Icon(
                              _categoryIcons[category],
                              size: 18,
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = category);
                              }
                            },
                            selectedColor: Colors.green.shade100,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Sarlavha",
                  hintText: "Murojaat mavzusini qisqacha yozing",
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Sarlavha kiriting";
                  }
                  if (value.length < 5) {
                    return "Sarlavha kamida 5 harf";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: "Batafsil ma'lumot",
                  hintText: "Muammoingizni batafsil tasvirlab bering...",
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ma'lumot kiriting";
                  }
                  if (value.length < 10) {
                    return "Ma'lumot kamida 10 harf";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Anonymous Switch
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    "Anonim yuborish",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Ismingiz ko'rsatilmaydi",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isAnonymous,
                  onChanged: (value) => setState(() => _isAnonymous = value),
                  activeColor: Colors.green.shade700,
                  secondary: Icon(
                    _isAnonymous ? Icons.visibility_off : Icons.visibility,
                    color: _isAnonymous ? Colors.grey : Colors.green.shade700,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text("Yuborish", style: TextStyle(fontSize: 18)),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Murojaatingiz ko'rib chiqilib, tez orada javob beriladi",
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
