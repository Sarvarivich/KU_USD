import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class MurojaatJavob extends StatefulWidget {
  final ComplaintModel complaint;
  const MurojaatJavob({required this.complaint});

  @override
  _MurojaatJavobState createState() => _MurojaatJavobState();
}

class _MurojaatJavobState extends State<MurojaatJavob> {
  final _formKey = GlobalKey<FormState>();
  int _cleanliness = 3;
  int _safety = 3;
  int _staffAttitude = 3;
  int _roomComfort = 3;
  int _facilities = 3;
  int _overallSatisfaction = 3;
  String _suggestions = '';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  Future<void> _submitSurvey() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      await FirebaseFirestore.instance.collection('surveys').add({
        'studentId': widget.complaint.studentId,
        'cleanliness': _cleanliness,
        'safety': _safety,
        'staffAttitude': _staffAttitude,
        'roomComfort': _roomComfort,
        'facilities': _facilities,
        'overallSatisfaction': _overallSatisfaction,
        'suggestions': _suggestions,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("So'rovnoma yuborildi! Rahmat."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        appBar: AppBar(
          title: Text("So'rovnoma"),
          backgroundColor: Colors.purple.shade700,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Rahmat!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Sizning fikringiz biz uchun muhim",
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Yotoqxonani yaxshilashda yordam berganingiz uchun tashakkur",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Yotoqxona so'rovnomasi"),
        backgroundColor: Colors.purple.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rate_review, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      "Fikr-mulohaza qoldiring",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Sizning fikringiz xizmat sifatini yaxshilashga yordam beradi",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Questions
              _ratingQuestion(
                "Tozalik va gigiena",
                _cleanliness,
                (val) => setState(() => _cleanliness = val),
              ),
              _ratingQuestion(
                "Xavfsizlik",
                _safety,
                (val) => setState(() => _safety = val),
              ),
              _ratingQuestion(
                "Xodimlar munosabati",
                _staffAttitude,
                (val) => setState(() => _staffAttitude = val),
              ),
              _ratingQuestion(
                "Xona qulayligi",
                _roomComfort,
                (val) => setState(() => _roomComfort = val),
              ),
              _ratingQuestion(
                "Qo'shimcha qulayliklar",
                _facilities,
                (val) => setState(() => _facilities = val),
              ),
              _ratingQuestion(
                "Umumiy qoniqish",
                _overallSatisfaction,
                (val) => setState(() => _overallSatisfaction = val),
              ),

              SizedBox(height: 16),

              // Suggestions
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
                        "Taklif va mulohazalar",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              "Yotoqxonani yaxshilash bo'yicha takliflaringiz...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (val) => _suggestions = val,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.purple.shade700,
                  ),
                  child: _isSubmitting
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingQuestion(String question, int value, Function(int) onChanged) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                int rating = index + 1;
                return GestureDetector(
                  onTap: () => onChanged(rating),
                  child: Column(
                    children: [
                      Icon(
                        rating <= value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "$rating",
                        style: TextStyle(
                          fontSize: 12,
                          color: rating <= value ? Colors.amber : Colors.grey,
                          fontWeight: rating == value
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yomon",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  "O'rtacha",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  "A'lo",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
