import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============ USER OPERATIONS ============

  Future<DocumentSnapshot> getUser(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<QuerySnapshot> getAllUsers() async {
    return await _firestore.collection('users').get();
  }

  Future<QuerySnapshot> getStudents() async {
    return await _firestore
        .collection('users')
        .where('role', isEqualTo: 'talaba')
        .get();
  }

  // ============ ROOM OPERATIONS ============

  Future<DocumentReference> addRoom(Map<String, dynamic> roomData) async {
    return await _firestore.collection('rooms').add(roomData);
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    await _firestore.collection('rooms').doc(roomId).update(data);
  }

  Future<void> deleteRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  Future<DocumentSnapshot> getRoom(String roomId) async {
    return await _firestore.collection('rooms').doc(roomId).get();
  }

  Stream<QuerySnapshot> getRoomsStream() {
    return _firestore.collection('rooms').snapshots();
  }

  Future<QuerySnapshot> getAllRooms() async {
    return await _firestore.collection('rooms').get();
  }

  Future<QuerySnapshot> getAvailableRooms() async {
    return await _firestore
        .collection('rooms')
        .where('status', isEqualTo: 'empty')
        .get();
  }

  // ============ COMPLAINT OPERATIONS ============

  Future<DocumentReference> addComplaint(
      Map<String, dynamic> complaintData) async {
    return await _firestore.collection('complaints').add(complaintData);
  }

  Future<void> updateComplaint(
      String complaintId, Map<String, dynamic> data) async {
    await _firestore.collection('complaints').doc(complaintId).update(data);
  }

  Future<void> deleteComplaint(String complaintId) async {
    await _firestore.collection('complaints').doc(complaintId).delete();
  }

  Stream<QuerySnapshot> getComplaintsStream(String? studentId) {
    if (studentId != null) {
      return _firestore
          .collection('complaints')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getPendingComplaints() async {
    return await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'pending')
        .get();
  }

  // ============ PAYMENT OPERATIONS ============

  Future<DocumentReference> addPayment(Map<String, dynamic> paymentData) async {
    return await _firestore.collection('payments').add(paymentData);
  }

  Future<QuerySnapshot> getStudentPayments(String studentId) async {
    return await _firestore
        .collection('payments')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .get();
  }

  Future<double> getTotalIncome() async {
    QuerySnapshot snapshot = await _firestore.collection('payments').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['amount'] ?? 0);
    }
    return total;
  }

  Future<Map<String, double>> getMonthlyIncome(int year) async {
    QuerySnapshot snapshot = await _firestore.collection('payments').get();
    Map<String, double> monthlyIncome = {};

    for (var doc in snapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      if (date.year == year) {
        String month = '${date.month}';
        monthlyIncome[month] =
            (monthlyIncome[month] ?? 0) + (doc['amount'] ?? 0);
      }
    }

    return monthlyIncome;
  }

  // ============ SURVEY OPERATIONS ============

  Future<DocumentReference> addSurvey(Map<String, dynamic> surveyData) async {
    return await _firestore.collection('surveys').add(surveyData);
  }

  Future<QuerySnapshot> getSurveys() async {
    return await _firestore.collection('surveys').get();
  }

  Future<double> getAverageRating() async {
    QuerySnapshot snapshot = await _firestore.collection('surveys').get();
    if (snapshot.docs.isEmpty) return 0;

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['overallSatisfaction'] ?? 0);
    }
    return total / snapshot.docs.length;
  }

  // ============ FILE UPLOAD OPERATIONS ============

  Future<String> uploadFile(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload file error: $e');
      return '';
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      print('Delete file error: $e');
    }
  }

  // ============ STATISTICS OPERATIONS ============

  Future<Map<String, dynamic>> getDashboardStats() async {
    Map<String, dynamic> stats = {};

    // Total students
    QuerySnapshot students = await getStudents();
    stats['totalStudents'] = students.docs.length;

    // Rooms stats
    QuerySnapshot rooms = await getAllRooms();
    stats['totalRooms'] = rooms.docs.length;
    stats['occupiedRooms'] =
        rooms.docs.where((doc) => doc['status'] == 'occupied').length;
    stats['emptyRooms'] =
        rooms.docs.where((doc) => doc['status'] == 'empty').length;

    // Complaints stats
    QuerySnapshot complaints = await _firestore.collection('complaints').get();
    stats['totalComplaints'] = complaints.docs.length;
    stats['pendingComplaints'] =
        complaints.docs.where((doc) => doc['status'] == 'pending').length;
    stats['resolvedComplaints'] =
        complaints.docs.where((doc) => doc['status'] == 'resolved').length;

    // Income
    stats['totalIncome'] = await getTotalIncome();

    return stats;
  }

  // ============ BATCH OPERATIONS ============

  Future<void> batchAssignRooms(Map<String, String> assignments) async {
    WriteBatch batch = _firestore.batch();

    for (var entry in assignments.entries) {
      String studentId = entry.key;
      String roomId = entry.value;

      DocumentReference studentRef =
          _firestore.collection('users').doc(studentId);
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);

      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();

      final roomNumber = roomDoc['roomNumber'].toString();

      batch.update(studentRef, {
        'roomId': roomNumber,
      });
      batch.update(roomRef, {
        'currentOccupants': FieldValue.increment(1),
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
    }

    await batch.commit();
  }

  // ============ REAL-TIME LISTENERS ============

  Stream<QuerySnapshot> listenToRooms() {
    return _firestore.collection('rooms').snapshots();
  }

  Stream<QuerySnapshot> listenToStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'talaba')
        .snapshots();
  }

  Stream<QuerySnapshot> listenToComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
