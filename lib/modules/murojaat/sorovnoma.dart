import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Sorovnoma extends StatefulWidget {
  final String studentId;
  const Sorovnoma({required this.studentId});

  @override
  _SorovnomaState createState() => _SorovnomaState();
}

class _SorovnomaState extends State<Sorovnoma> {
  final _formKey = GlobalKey<FormState>();

  // Rating values (1-5)
  int _cleanliness = 3;
  int _safety = 3;
  int _staffAttitude = 3;
  int _roomComfort = 3;
  int _facilities = 3;
  int _overallSatisfaction = 3;

  String _suggestions = '';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final Map<String, Map<String, dynamic>> _questions = {
    'cleanliness': {
      'title': "Tozalik va gigiena",
      'icon': Icons.cleaning_services,
      'color': Colors.blue,
    },
    'safety': {
      'title': "Xavfsizlik",
      'icon': Icons.security,
      'color': Colors.green,
    },
    'staffAttitude': {
      'title': "Xodimlar munosabati",
      'icon': Icons.people,
      'color': Colors.orange,
    },
    'roomComfort': {
      'title': "Xona qulayligi",
      'icon': Icons.bed,
      'color': Colors.purple,
    },
    'facilities': {
      'title': "Qo'shimcha qulayliklar (WiFi, suv, elektr)",
      'icon': Icons.wifi,
      'color': Colors.teal,
    },
    'overallSatisfaction': {
      'title': "Umumiy qoniqish",
      'icon': Icons.star,
      'color': Colors.amber,
    },
  };

  Future<void> _submitSurvey() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        await FirebaseFirestore.instance.collection('surveys').add({
          'studentId': widget.studentId,
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
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Xatolik: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        appBar: AppBar(
          title: Text("So'rovnoma"),
          backgroundColor: Colors.purple.shade700,
          elevation: 0,
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
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Sizning fikringiz biz uchun muhim",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.rate_review, size: 50, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Fikr-mulohaza qoldiring",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Sizning fikringiz xizmat sifatini yaxshilashga yordam beradi",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Questions
              _buildRatingQuestion(
                key: 'cleanliness',
                value: _cleanliness,
                onChanged: (val) => setState(() => _cleanliness = val),
              ),
              _buildRatingQuestion(
                key: 'safety',
                value: _safety,
                onChanged: (val) => setState(() => _safety = val),
              ),
              _buildRatingQuestion(
                key: 'staffAttitude',
                value: _staffAttitude,
                onChanged: (val) => setState(() => _staffAttitude = val),
              ),
              _buildRatingQuestion(
                key: 'roomComfort',
                value: _roomComfort,
                onChanged: (val) => setState(() => _roomComfort = val),
              ),
              _buildRatingQuestion(
                key: 'facilities',
                value: _facilities,
                onChanged: (val) => setState(() => _facilities = val),
              ),
              _buildRatingQuestion(
                key: 'overallSatisfaction',
                value: _overallSatisfaction,
                onChanged: (val) => setState(() => _overallSatisfaction = val),
              ),

              SizedBox(height: 16),

              // Suggestions Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.purple.shade700),
                          SizedBox(width: 8),
                          Text(
                            "Taklif va mulohazalar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              "Yotoqxonani yaxshilash bo'yicha takliflaringiz...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: EdgeInsets.all(16),
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

              SizedBox(height: 16),

              // Info Text
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
                        "Sizning javoblaringiz anonim tarzda saqlanadi va faqat statistika uchun ishlatiladi",
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

  Widget _buildRatingQuestion({
    required String key,
    required int value,
    required Function(int) onChanged,
  }) {
    Map<String, dynamic> question = _questions[key]!;

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (question['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    question['icon'],
                    color: question['color'],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question['title'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                int rating = index + 1;
                return GestureDetector(
                  onTap: () => onChanged(rating),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        Icon(
                          rating <= value ? Icons.star : Icons.star_border,
                          color: rating <= value
                              ? Colors.amber
                              : Colors.grey.shade400,
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
                  ),
                );
              }),
            ),
            SizedBox(height: 8),

            // Rating Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Yomon",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text("Qoniqarsiz",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text("O'rtacha",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text("Yaxshi",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text("A'lo",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
