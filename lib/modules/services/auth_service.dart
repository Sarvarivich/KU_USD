import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:yotoqxona/modules/models/user_model.dart';

// ─── AuthService: endi TO'LIQ Firebase Authentication'ga asoslangan ───
// ✅ Parollar endi Firestore'da ochiq matn (plain text) holida
//    SAQLANMAYDI. Ularni Firebase Authentication o'zi xavfsiz
//    boshqaradi (hash'langan holda). Firestore'dagi `users/{uid}`
//    hujjati faqat profil ma'lumotlarini (ism, rol, telefon va h.k.)
//    saqlaydi, hujjat ID'si esa Firebase Auth UID bilan bir xil bo'ladi.
class AuthService {
  static final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Firebase login xatolik kodlarini talabaga tushunarli xabarga aylantiradi
  static String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Email yoki parol xato!";
      case 'invalid-email':
        return "Email formati noto'g'ri";
      case 'user-disabled':
        return "Bu hisob bloklangan";
      case 'email-already-in-use':
        return "Bu email band!";
      case 'weak-password':
        return "Parol juda oddiy — kamida 6 ta belgi bo'lishi kerak";
      case 'network-request-failed':
        return "Internet aloqasi yo'q, qaytadan urinib ko'ring";
      default:
        return e.message ?? "Noma'lum xatolik: ${e.code}";
    }
  }

  // 1. TALABANING O'ZI RO'YXATDAN O'TISHI
  static Future<void> registerAndLoginUser({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? phoneNumber,
    String? faculty,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      // ✅ Firebase Authentication orqali haqiqiy hisob yaratamiz.
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      final uid = credential.user!.uid;

      final newUser = UserModel(
        id: uid,
        fullName: fullName.trim(),
        email: cleanEmail,
        phoneNumber: phoneNumber?.trim() ?? "+998900000000",
        role: role,
        faculty: faculty,
      );

      // ✅ Firestore hujjat ID'si endi Auth UID bilan bir xil, va
      // parol maydoni umuman yozilmaydi.
      await _usersCollection.doc(uid).set(newUser.toJson());

      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Muvaffaqiyatli ro'yxatdan o'tdingiz!"),
            backgroundColor: Colors.green),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_friendlyAuthError(e)), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Xatolik yuz berdi: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // 2. ADMIN/MUDIR ICHKARIDAN YANGI FOYDALANUVCHI QO'SHISHI
  // ✅ Ikkinchi (vaqtinchalik) Firebase ilova nusxasidan foydalanadi —
  // shunda yangi hisob yaratilganda hozir tizimga kirgan admin/mudir
  // hisobidan avtomatik chiqib ketmaydi.
  static Future<bool> addUserByAdmin({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? phoneNumber,
    String? faculty,
    Map<String, dynamic>? extraData,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final credential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      final uid = credential.user!.uid;

      final newUser = UserModel(
        id: uid,
        fullName: fullName.trim(),
        email: cleanEmail,
        phoneNumber: phoneNumber?.trim() ?? "+998900000000",
        role: role,
        faculty: faculty,
      );

      await _usersCollection.doc(uid).set({
        ...newUser.toJson(),
        if (extraData != null) ...extraData,
      });

      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Yangi foydalanuvchi muvaffaqiyatli qo'shildi!"),
              backgroundColor: Colors.green),
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_friendlyAuthError(e)),
              backgroundColor: Colors.red),
        );
      }
      return false;
    } catch (e) {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: $e"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ✅ Foydalanuvchini TO'LIQ o'chirish (Firestore + Firebase Authentication).
  // Bitta `deleteUserAccount` Cloud Function'ini chaqiradi — shu tufayli
  // Auth va Firestore hech qachon bir-biridan orqada qolmaydi.
  // (Client SDK boshqa foydalanuvchini Auth'dan o'chira olmaydi, shuning
  // uchun bu amal serverda, Admin SDK yordamida bajariladi.)
  static Future<void> deleteUserAccount(String uid) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
    try {
      await callable.call({'uid': uid});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "O'chirishda xatolik: ${e.code}");
    }
  }

  // 3. TIZIMGA KIRISH (LOGIN)
  // ✅ Endi Firestore'dan parol solishtirmaydi — haqiqiy Firebase
  // Authentication orqali tekshiradi, keyin profilni UID bo'yicha oladi.
  static Future<UserModel?> loginUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final inputEmail = email.trim().toLowerCase();
      final inputPassword = password.trim();

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: inputEmail,
        password: inputPassword,
      );

      final uid = credential.user!.uid;
      final docSnap = await _usersCollection.doc(uid).get();

      if (!context.mounted) return null;
      Navigator.of(context).pop();

      if (docSnap.exists) {
        final docData = docSnap.data() as Map<String, dynamic>;
        return UserModel.fromJson(docData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Hisob topildi, lekin profil ma'lumotlari yo'q. Administratorga murojaat qiling."),
              backgroundColor: Colors.red),
        );
        return null;
      }
    } on FirebaseAuthException catch (e) {
      // 🔍 Debug: aniq Firebase xato kodini konsolga chiqaramiz
      debugPrint('🔴 Firebase Auth xato kodi: ${e.code} | Xabar: ${e.message}');
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_friendlyAuthError(e)), backgroundColor: Colors.red),
      );
      return null;
    } catch (e) {
      debugPrint('🔴 Login xatoligi (kutilmagan): $e');
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Login xatoligi: $e"), backgroundColor: Colors.red),
      );
      return null;
    }
  }
}
