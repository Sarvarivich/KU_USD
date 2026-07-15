// Talaba ro'yxatdan o'tishda va profilida tanlaydigan fakultetlar ro'yxati
const List<String> kFaculties = [
  'Turizm va Iqtisodiyot fakulteti',
  "Ta'lim fakulteti",
];

enum UserRole {
  talaba('talaba'),
  mudir('mudir'),
  moliyachi('moliyachi'),
  superAdmin('superAdmin');

  final String name;
  const UserRole(this.name);

  factory UserRole.fromString(String value) {
    // ⚠️ Diagnostika: agar Firestore'dagi "role" maydoni
    // enum qiymatlaridan ('talaba', 'mudir', 'moliyachi', 'superAdmin')
    // birortasiga ANIQ mos kelmasa (masalan bo'sh, boshqa yozilishda,
    // katta-kichik harf xato bo'lsa), tizim JIMgina "talaba"ga
    // tushirib yuboradi. Shu sabab admin login qilganda oddiy
    // profil bo'lib kirib qolishi mumkin. Shuning uchun bu holatni
    // konsolga chiqaramiz — Firestore'dagi haqiqiy qiymatni tekshirish
    // uchun.
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () {
        // ignore: avoid_print
        print(
            '⚠️ UserRole.fromString: Noma\'lum rol qiymati topildi: "$value". '
            'Firestore\'dagi "foydalanuvchilar/{uid}" hujjatida "role" '
            'maydoni aniq "superAdmin" / "mudir" / "moliyachi" / "talaba" '
            'so\'zlaridan biriga teng ekanini tekshiring (katta-kichik harf, '
            'bo\'shliq va yozilishiga e\'tibor bering). Vaqtincha "talaba" '
            'sifatida kirilmoqda.');
        return UserRole.talaba;
      },
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String? fcmToken;
  final String? studentId;
  final String? roomId;
  final String? faculty;
  final String? passportId;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.fcmToken,
    this.studentId,
    this.roomId,
    this.faculty,
    this.passportId,
    this.birthDate,
    this.createdAt,
    this.additionalData,
  });

  String get name => fullName;
  String get phone => phoneNumber;

  // Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'fcmToken': fcmToken,
      'studentId': studentId,
      'roomId': roomId,
      'faculty': faculty,
      'passportId': passportId,
      'birthDate': birthDate,
      'createdAt': createdAt,
      ...?additionalData,
    };
  }

  // Create UserModel from JSON from Firestore
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsed = Map<String, dynamic>.from(json);
    final metadata = Map<String, dynamic>.from(parsed);
    metadata.removeWhere((key, value) => [
          'id',
          'fullName',
          'name',
          'email',
          'phoneNumber',
          'phone',
          'role',
          'fcmToken',
          'studentId',
          'roomId',
          'faculty',
          'passportId',
          'birthDate',
          'createdAt',
        ].contains(key));

    return UserModel(
      id: parsed['id'] as String? ?? '',
      fullName:
          (parsed['fullName'] as String?) ?? (parsed['name'] as String?) ?? '',
      email: parsed['email'] as String? ?? '',
      phoneNumber: (parsed['phoneNumber'] as String?) ??
          (parsed['phone'] as String?) ??
          '',
      role: UserRole.fromString(parsed['role'] as String? ?? 'talaba'),
      fcmToken: parsed['fcmToken'] as String?,
      studentId: parsed['studentId'] as String?,
      roomId: parsed['roomId'] as String?,
      faculty: parsed['faculty'] as String?,
      passportId: parsed['passportId'] as String?,
      birthDate: parsed['birthDate'] != null
          ? (parsed['birthDate'] as dynamic).toDate()
          : null,
      createdAt: parsed['createdAt'] != null
          ? (parsed['createdAt'] as dynamic).toDate()
          : null,
      additionalData: metadata.isNotEmpty ? metadata : null,
    );
  }

  // Create a copy with modified fields
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? fcmToken,
    String? studentId,
    String? roomId,
    String? faculty,
    String? passportId,
    DateTime? birthDate,
    DateTime? createdAt,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      studentId: studentId ?? this.studentId,
      roomId: roomId ?? this.roomId,
      faculty: faculty ?? this.faculty,
      passportId: passportId ?? this.passportId,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
