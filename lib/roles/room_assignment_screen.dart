import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/models/room_model.dart';
import '../modules/models/user_model.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String roomDocId;
  final RoomModel room;

  const RoomDetailsScreen({
    super.key,
    required this.roomDocId,
    required this.room,
  });

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  String? selectedStudentId; // Tanlangan talaba ID-si uchun

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('roomId', isEqualTo: widget.room.roomNumber.toString())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<DocumentSnapshot> assignedStudents =
            snapshot.hasData ? snapshot.data!.docs : [];

        final int currentStudentsCount = assignedStudents.length;
        final int capacity =
            widget.room.capacity > 0 ? widget.room.capacity : 4;
        bool isRoomFull = currentStudentsCount >= capacity;

        return Scaffold(
          appBar: AppBar(
            title: Text("${widget.room.roomNumber}-xona ma'lumotlari"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Xona holati (Dinamik blok)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: isRoomFull
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${widget.room.roomNumber}",
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        "${widget.room.floor}-qavat",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          isRoomFull ? "Band" : "Bo'sh",
                          style: TextStyle(
                              color: isRoomFull ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Xona ma'lumotlari kartasi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Xona ma'lumotlari",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          ListTile(
                            leading:
                                const Icon(Icons.people, color: Colors.blue),
                            title: const Text("Sig'imi:"),
                            trailing: Text("$capacity kishi"),
                          ),
                          ListTile(
                            leading: Icon(Icons.person,
                                color: isRoomFull ? Colors.red : Colors.green),
                            title: const Text("Hozirgi bandlik:"),
                            trailing: Text("$currentStudentsCount / $capacity"),
                          ),
                          ListTile(
                            leading:
                                const Icon(Icons.money, color: Colors.orange),
                            title: const Text("Oylik to'lov:"),
                            trailing: Text("${widget.room.pricePerMonth} so'm"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. TALABA BIRIKTIRISH FUNKSIYASI (QIDIRUVSIZ, TOZA DROPDOWN)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRoomFull) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              "Ushbu xona to'lgan / band!",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text("Yangi talaba biriktirish",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // Hech qaysi xonaga biriktirilmagan talabalar ro'yxatini olish
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'talaba')
                              .snapshots(),
                          builder: (context, studentSnapshot) {
                            if (!studentSnapshot.hasData) {
                              return const LinearProgressIndicator();
                            }

                            // Faqat roomId bo'sh bo'lgan talabalarni filterlash
                            final freeStudents =
                                studentSnapshot.data!.docs.where((doc) {
                              final student = UserModel.fromJson(
                                  doc.data() as Map<String, dynamic>);
                              return student.roomId == null ||
                                  student.roomId == "";
                            }).toList();

                            if (freeStudents.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "⚠️ Xonaga joylashtirilmagan bo'sh talabalar qolmagan.",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }

                            // Dropdown uchun doim UNIKAL va MAVJUD qiymatlardan
                            // foydalanamiz: Firestore doc.id (student.id emas,
                            // chunki u bo'sh/bir xil bo'lib qolishi mumkin).
                            final freeStudentIds =
                                freeStudents.map((doc) => doc.id).toSet();

                            // Agar tanlangan talaba ro'yxatdan chiqib ketgan
                            // bo'lsa (masalan, Firestore optimistik yozuvi
                            // sabab ro'yxat darhol yangilanib ketsa, ammo
                            // selectedStudentId hali null qilinmagan bo'lsa),
                            // dropdown value'sini xavfsiz ravishda null qilib
                            // yuboramiz — shu orqali "0 yoki 2+" assertion
                            // xatoligining oldi olinadi.
                            final safeValue =
                                freeStudentIds.contains(selectedStudentId)
                                    ? selectedStudentId
                                    : null;

                            return DropdownButtonFormField<String>(
                              value: safeValue,
                              hint:
                                  const Text("Xonasi yo'q talabalar ro'yxati"),
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              items: freeStudents.map((doc) {
                                final student = UserModel.fromJson(
                                    doc.data() as Map<String, dynamic>);
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(student.fullName),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => selectedStudentId = val),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Biriktirish tugmasi
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: selectedStudentId == null
                                ? null
                                : () async {
                                    final String studentId = selectedStudentId!;
                                    final batch =
                                        FirebaseFirestore.instance.batch();

                                    final userRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(studentId);
                                    final roomRef = FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(widget.roomDocId);

                                    batch.update(userRef, {
                                      'roomId':
                                          widget.room.roomNumber.toString()
                                    });
                                    batch.update(roomRef, {
                                      'currentOccupants':
                                          FieldValue.increment(1),
                                      'studentIds':
                                          FieldValue.arrayUnion([studentId]),
                                      // 🛠️ Xona to'lib qolsa, holatini ham
                                      // avtomatik "band" (occupied) qilib
                                      // qo'yamiz — aks holda statistika va
                                      // Dashboard'da xona "bo'sh" bo'lib
                                      // ko'rinib qolaveradi.
                                      'status':
                                          (currentStudentsCount + 1) >= capacity
                                              ? RoomStatus.occupied.name
                                              : widget.room.status.name,
                                    });

                                    await batch.commit();

                                    setState(() {
                                      selectedStudentId = null;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Talaba xonaga muvaffaqiyatli biriktirildi!")),
                                    );
                                  },
                            child: const Text("Talabani biriktirish",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 4. Yashovchi talabalar ro'yxati
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Yashovchi talabalar",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("$currentStudentsCount ta",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (assignedStudents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Bu xonada hozircha hech kim yashamaydi.",
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: assignedStudents.length,
                          itemBuilder: (context, index) {
                            final studentDoc = assignedStudents[index];
                            final student = UserModel.fromJson(
                                studentDoc.data() as Map<String, dynamic>);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: Colors.purple.shade100,
                                    child: Text(
                                        student.fullName.isNotEmpty
                                            ? student.fullName[0].toUpperCase()
                                            : "?",
                                        style: const TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold))),
                                title: Text(student.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(student.phoneNumber),
                                trailing: IconButton(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final String studentId = studentDoc.id;

                                    final batch =
                                        FirebaseFirestore.instance.batch();
                                    final userRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(studentId);
                                    final roomRef = FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(widget.roomDocId);

                                    batch.update(userRef, {'roomId': ""});
                                    batch.update(roomRef, {
                                      'currentOccupants':
                                          FieldValue.increment(-1),
                                      'studentIds':
                                          FieldValue.arrayRemove([studentId]),
                                      // 🛠️ Agar xona avtomatik "band" deb
                                      // belgilangan bo'lsa-yu, endi joy
                                      // bo'shagan bo'lsa — holatini "bo'sh"ga
                                      // qaytaramiz. Admin qo'lda "Ta'mirlashda"
                                      // yoki "To'lov kutilmoqda" deb qo'ygan
                                      // bo'lsa, bu holatlarga tegmaymiz.
                                      'status': (widget.room.status ==
                                                  RoomStatus.occupied &&
                                              (currentStudentsCount - 1) <
                                                  capacity)
                                          ? RoomStatus.empty.name
                                          : widget.room.status.name,
                                    });

                                    await batch.commit();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Talaba xonadan chiqarildi.")),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
