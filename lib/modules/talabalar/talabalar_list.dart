import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yotoqxona/modules/models/user_model.dart';

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

class TalabalarList extends StatefulWidget {
  final bool isAdmin;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const TalabalarList({super.key, required this.isAdmin, this.scaffoldKey});

  @override
  State<TalabalarList> createState() => _TalabalarListState();
}

class _TalabalarListState extends State<TalabalarList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    final query = _searchQuery.toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fullName = (data['fullName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      return fullName.contains(query) || email.contains(query);
    }).toList();
  }

  // Foydalanuvchini o'chirishdan oldin tasdiqlash dialogi
  void _confirmDelete(BuildContext context, String docId, String fullName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _LC.coral),
            SizedBox(width: 8),
            Text('O\'chirishni tasdiqlang'),
          ],
        ),
        content: Text(
          '"$fullName" foydalanuvchisini tizimdan butunlay o\'chirmoqchimisiz?\n\nBu amalni qaytarib bo\'lmaydi!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label:
                const Text('O\'chirish', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteUser(context, docId, fullName);
            },
          ),
        ],
      ),
    );
  }

  // 🗑️ Foydalanuvchini xavfsiz o'chirish:
  // - Barcha yozuvlar (xona yangilanishi + user hujjatini o'chirish) BITTA
  //   atomik "batch" ichida yuboriladi. Avvalgi versiyada bu amallar ketma-ket
  //   (bir nechta alohida await) bajarilar edi — shu paytda ekranda ochiq
  //   turgan StreamBuilder("users".snapshots()) oraliq holatni ko'rib qolib,
  //   Firestore SDK ichida "internal" xatolikni chaqirib yuborishi mumkin edi.
  // - "internal"/"unavailable" kabi vaqtinchalik (transient) xatoliklar
  //   Firestore'ning o'zida ma'lum muammo bo'lgani uchun, birinchi urinish
  //   muvaffaqiyatsiz bo'lsa, qisqa kutishdan so'ng avtomatik ravishda
  //   yana bir marta qayta uriniladi.
  Future<void> _deleteUser(
    BuildContext context,
    String docId,
    String fullName, {
    int attempt = 1,
  }) async {
    try {
      // Talaba biriktirilgan xona(lar)ni topib, undan chiqarib olamiz —
      // aks holda xona sig'imi (currentOccupants/studentIds) eskicha qolib
      // ketadi.
      final roomsSnap = await _firestore
          .collection('rooms')
          .where('studentIds', arrayContains: docId)
          .get();

      final batch = _firestore.batch();
      for (final roomDoc in roomsSnap.docs) {
        batch.update(roomDoc.reference, {
          'studentIds': FieldValue.arrayRemove([docId]),
          'currentOccupants': FieldValue.increment(-1),
        });
      }
      batch.delete(_firestore.collection('users').doc(docId));
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$fullName" muvaffaqiyatli o\'chirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      // Firestore'ning o'zi tomonidan qaytariladigan vaqtinchalik xatoliklar
      // ("internal", "unavailable", "aborted") uchun 1 marta qayta urinamiz.
      final isTransient = e.code == 'internal' ||
          e.code == 'unavailable' ||
          e.code == 'aborted' ||
          e.code == 'unknown';
      if (isTransient && attempt < 3) {
        await Future.delayed(Duration(milliseconds: 400 * attempt));
        return _deleteUser(context, docId, fullName, attempt: attempt + 1);
      }
      if (context.mounted) {
        final message = e.code == 'permission-denied'
            ? 'Sizda bu foydalanuvchini o\'chirish uchun ruxsat yo\'q.'
            : 'O\'chirishda xatolik (${e.code}): ${e.message ?? e.code}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('O\'chirishda xatolik: $e'),
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
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: _isSearching
            ? null
            : widget.scaffoldKey != null
                ? IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () =>
                        widget.scaffoldKey!.currentState?.openDrawer(),
                  )
                : null,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_LC.purple, _LC.violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Ism yoki email bo\'yicha izlash...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.white70),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              )
            : const Text(
                'Talabalar va Hodimlar',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _LC.purple));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 56, color: _LC.muted),
                  const SizedBox(height: 12),
                  const Text(
                    "Foydalanuvchilar topilmadi.",
                    style: TextStyle(
                        fontSize: 15,
                        color: _LC.muted,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          final docs = _filterDocs(snapshot.data!.docs);

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 56, color: _LC.muted),
                  const SizedBox(height: 12),
                  Text(
                    '"$_searchQuery" bo\'yicha natija topilmadi',
                    style: const TextStyle(
                        color: _LC.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final docData = doc.data() as Map<String, dynamic>;
              // Hujjat ichidagi 'id' maydoniga emas, Firestore'ning
              // haqiqiy hujjat ID'siga tayanamiz — aks holda 'id' maydoni
              // yo'q yoki bo'sh bo'lgan (masalan eski) foydalanuvchilarda
              // keyinchalik parol/ma'lumot yangilashda
              // "A document path must be a non-empty string" xatoligi chiqadi.
              docData['id'] = doc.id;
              final currentUser = UserModel.fromJson(docData);
              final roleColor = _getRoleColor(currentUser.role);

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
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (widget.isAdmin) {
                        _openUserManagementDialog(context, currentUser);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Profilni ko'rish faqat adminlar uchun!")),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.person_rounded, color: roleColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: _LC.ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  currentUser.email,
                                  style: const TextStyle(
                                      color: _LC.muted, fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentUser.role
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: roleColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (widget.isAdmin) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _confirmDelete(
                                      context, doc.id, currentUser.fullName),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: _LC.coral,
                                      size: 19),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Rollarga qarab rang ajratish uchun yordamchi funksiya
  Color _getRoleColor(UserRole role) {
    switch (role.toString().split('.').last) {
      case 'admin':
        return _LC.coral;
      case 'mudir':
        return _LC.purple;
      case 'manager':
        return _LC.orange;
      default:
        return _LC.teal;
    }
  }

  // 🏠 Talabaga biriktirilgan xona haqida ma'lumot olish
  // (rooms kolleksiyasidan studentIds massivi orqali qidiriladi)
  Future<String?> _getAssignedRoomInfo(String userId) async {
    try {
      final snap = await _firestore
          .collection('rooms')
          .where('studentIds', arrayContains: userId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final roomData = snap.docs.first.data();
        final roomNumber = roomData['roomNumber']?.toString() ?? '-';
        final floor = roomData['floor']?.toString() ?? '-';
        return "$roomNumber-xona ($floor-qavat)";
      }
      return null; // Xonaga biriktirilmagan
    } catch (e) {
      return "Xatolik: $e";
    }
  }

  // 🌟 Dialogni ochishdan oldin (agar talaba bo'lsa) xona ma'lumotini
  // oldindan yuklab olamiz — shu tufayli dialog ichida "Yuklanmoqda..."
  // holatida osilib qolish muammosi butunlay bartaraf etiladi.
  Future<void> _openUserManagementDialog(
      BuildContext context, UserModel selectedUser) async {
    String? roomInfo;
    if (selectedUser.role == UserRole.talaba) {
      roomInfo = await _getAssignedRoomInfo(selectedUser.id);
    }
    if (!context.mounted) return;
    _showUserManagementDialog(context, selectedUser,
        assignedRoomInfo: roomInfo);
  }

  // 🌟 ADMIN UCHUN TANLANGAN FOYDALANUVCHINI BOSGANDA CHIQUVCHI ASOSIY DIALOG
  void _showUserManagementDialog(BuildContext context, UserModel selectedUser,
      {String? assignedRoomInfo}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.manage_accounts, color: _LC.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedUser.fullName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor:
                      _getRoleColor(selectedUser.role).withOpacity(0.1),
                  child: Icon(Icons.person,
                      size: 40, color: _getRoleColor(selectedUser.role)),
                ),
                const SizedBox(height: 16),

                // 1. FIO Ko'rinishi va tahrirlash
                ListTile(
                  leading: const Icon(Icons.person_outline, color: _LC.purple),
                  title: const Text("FIO"),
                  subtitle: Text(selectedUser.fullName),
                  trailing:
                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _editUserField(context, selectedUser, "FIO", "fullName",
                        selectedUser.fullName);
                  },
                ),

                // 2. Telefon Ko'rinishi va tahrirlash
                ListTile(
                  leading: const Icon(Icons.phone_android, color: _LC.teal),
                  title: const Text("Telefon"),
                  subtitle: Text(selectedUser.phoneNumber ?? "Kiritilmagan"),
                  trailing:
                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _editUserField(context, selectedUser, "Telefon",
                        "phoneNumber", selectedUser.phoneNumber ?? "");
                  },
                ),

                // 3. Email (O'zgartirib bo'lmaydi)
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.grey),
                  title: const Text("Email"),
                  subtitle: Text(selectedUser.email),
                ),

                // 4. Rol ko'rinishi
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Colors.purple),
                  title: const Text("Tizimdagi roli"),
                  subtitle: Text(selectedUser.role
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase()),
                ),

                // 4.1. Faqat talabalar uchun: biriktirilgan xona ma'lumoti
                if (selectedUser.role == UserRole.talaba)
                  ListTile(
                    leading: const Icon(Icons.meeting_room_outlined,
                        color: _LC.teal),
                    title: const Text("Biriktirilgan xona"),
                    subtitle: Text(
                      assignedRoomInfo ?? "Hali xonaga biriktirilmagan",
                      style: TextStyle(
                        color: assignedRoomInfo != null &&
                                !assignedRoomInfo.startsWith("Xatolik")
                            ? _LC.ink
                            : _LC.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Divider(),

                // 🔐 5. ADMIN UCHUN PAROLNI TO'G'RIDAN-TO'G'RI YANGILASH
                ListTile(
                  leading: const Icon(Icons.lock_open, color: _LC.coral),
                  title: const Text(
                    "Parolni majburiy yangilash",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.red),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _adminChangeUserPassword(context, selectedUser);
                  },
                ),

                const Divider(),

                // 🗑️ 6. FOYDALANUVCHINI O'CHIRISH
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: _LC.coral),
                  title: const Text(
                    "Foydalanuvchini o'chirish",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.red),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _confirmDelete(
                        context, selectedUser.id, selectedUser.fullName);
                  },
                ),
              ],
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Yopish"),
            ),
          ],
        );
      },
    );
  }

  // 📝 FOYDALANUVCHI MA'LUMOTLARINI (FIO, TELEFON) TAHRIRLASH DIALOGI
  void _editUserField(BuildContext context, UserModel selectedUser,
      String label, String fieldName, String currentValue) {
    final TextEditingController fieldController =
        TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$label tahrirlash"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: fieldController,
            decoration: InputDecoration(
              labelText: label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? "Maydon bo'sh bo'lishi mumkin emas"
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openUserManagementDialog(context, selectedUser);
            },
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              String newValue = fieldController.text.trim();
              try {
                await _firestore
                    .collection('users')
                    .doc(selectedUser.id)
                    .update({fieldName: newValue});

                if (context.mounted) {
                  Navigator.pop(context);
                  final updatedUser = UserModel(
                    id: selectedUser.id,
                    fullName: fieldName == 'fullName'
                        ? newValue
                        : selectedUser.fullName,
                    email: selectedUser.email,
                    role: selectedUser.role,
                    phoneNumber: fieldName == 'phoneNumber'
                        ? newValue
                        : selectedUser.phoneNumber,
                  );
                  _openUserManagementDialog(context, updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("$label muvaffaqiyatli o'zgartirildi!"),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Xatolik yuz berdi: $e"),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Saqlash", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔐 ADMIN UCHUN FOYDALANUVCHI PAROLINI MAJBURIY YANGILASH DIALOGI
  void _adminChangeUserPassword(BuildContext context, UserModel selectedUser) {
    final TextEditingController newPasswordController = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: _LC.coral),
                  SizedBox(width: 8),
                  Text("Yangi parol o'rnatish"),
                ],
              ),
              content: Form(
                key: passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${selectedUser.fullName} uchun yangi kirish parolini belgilang.",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Yangi kirish paroli",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setDialogState(
                              () => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Parol kiriting";
                        if (value.length < 6)
                          return "Parol kamida 6 belgidan iborat bo'lsin";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openUserManagementDialog(context, selectedUser);
                  },
                  child: const Text("Bekor qilish"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!passwordFormKey.currentState!.validate()) return;
                    try {
                      await _firestore
                          .collection('users')
                          .doc(selectedUser.id)
                          .update(
                              {'password': newPasswordController.text.trim()});
                      if (context.mounted) {
                        Navigator.pop(context);
                        _openUserManagementDialog(context, selectedUser);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Foydalanuvchi paroli muvaffaqiyatli o'zgartirildi!"),
                              backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Parol yangilanishida xatolik: $e"),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Yangilash",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
