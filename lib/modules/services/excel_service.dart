import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import '../models/user_model.dart';
import 'excel_download.dart';

class ExcelExportService {
  static Future<void> exportTalabalarToExcel() async {
    try {
      // 1. Firebase Firestore'dan talabalarni olamiz
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'talaba') // yoki UserRole.talaba.name
          .get();

      if (snapshot.docs.isEmpty) {
        print("Eksport qilish uchun talabalar topilmadi.");
        return;
      }

      // 2. Excel yaratish
      var excel = Excel.createExcel();
      String sheetName = "Talabalar Ro'yxati";
      Sheet sheetObject = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // 3. JADVAL BOSHI (Header) — CellValue orqali yoziladi
      sheetObject.appendRow([
        TextCellValue("T/r"),
        TextCellValue("Foydalanuvchi ID"),
        TextCellValue("To'liq ismi (F.I.O)"),
        TextCellValue("Email"),
        TextCellValue("Telefon raqami"),
        TextCellValue("Xona raqami"),
      ]);

      // 4. MA'LUMOTLARNI QATORMA-QATOR QO'SHISH
      int index = 1;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // UserModel'ga o'giramiz (Siz yozgan model maydonlari bo'yicha)
        final student = UserModel.fromJson(data);

        sheetObject.appendRow([
          IntCellValue(index), // int turi uchun IntCellValue
          TextCellValue(doc.id), // String turlari uchun TextCellValue
          TextCellValue(student.fullName),
          TextCellValue(student.email),
          TextCellValue(student.phoneNumber),
          TextCellValue(student.roomId ?? "Biriktirilmagan"),
        ]);
        index++;
      }

      // 5. Faylni platformaga mos usulda yuklab olish / ulashish
      // (Web'da brauzer orqali yuklanadi, mobil/desktopda vaqtinchalik
      // papkaga yozilib ulashish oynasi ochiladi)
      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await downloadExcelBytes(
          fileBytes,
          'Yotoqxona_Talabalar_Ruyxati.xlsx',
        );
      }
    } catch (e) {
      print("Excel eksportda xatolik: $e");
      rethrow;
    }
  }
}
