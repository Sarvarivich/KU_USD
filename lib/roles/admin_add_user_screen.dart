import 'package:flutter/material.dart';
import '../modules/models/user_model.dart';
import '../modules/services/auth_service.dart';

class AdminAddUserScreen extends StatefulWidget {
  const AdminAddUserScreen({super.key});

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedRole = 'talaba'; // Default rol
  bool _isLoading = false;

  // Admin huquqlari (Faqat rol 'admin' bo'lsa ishlaydi)
  final Map<String, bool> permissions = {
    'canEditRooms': false,
    'canDeleteUsers': false,
    'canExportExcel': false,
  };

  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // ✅ Firebase Authentication orqali xavfsiz hisob yaratiladi —
      // parol endi Firestore'ga umuman yozilmaydi.
      await AuthService.addUserByAdmin(
        context: context,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: UserRole.fromString(_selectedRole),
        extraData:
            _selectedRole == 'superAdmin' ? {'permissions': permissions} : null,
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yangi foydalanuvchi qo'shish")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: "To'liq ismi (F.I.O)",
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Ismni kiriting" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: "Email", border: OutlineInputBorder()),
                        validator: (v) =>
                            v!.isEmpty ? "Emailni kiriting" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: "Parol (kamida 6 ta belgi)",
                            border: OutlineInputBorder()),
                        validator: (v) =>
                            v!.length < 6 ? "Parol juda qisqa" : null,
                      ),
                      const SizedBox(height: 16),

                      // ROLNI TANLASH DROPDOWN
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                            labelText: "Rolni tanlang",
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'superAdmin', child: Text('ADMIN')),
                          DropdownMenuItem(
                              value: 'mudir', child: Text('MUDIR')),
                          DropdownMenuItem(
                              value: 'moliyachi', child: Text('MOLIYACHI')),
                          DropdownMenuItem(
                              value: 'talaba', child: Text('TALABA')),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedRole = val!),
                      ),
                      const SizedBox(height: 16),

                      // 🔐 ADMIN HUQUQLARI (FAKAT ADMIN TANLANGANDA CHIQADI)
                      if (_selectedRole == 'superAdmin') ...[
                        const Card(
                          color: Colors.blueGrey,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Admin huquqlarini sozlash",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        CheckboxListTile(
                          title: const Text("Xonalarni tahrirlash huquqi"),
                          value: permissions['canEditRooms'],
                          onChanged: (val) => setState(
                              () => permissions['canEditRooms'] = val!),
                        ),
                        CheckboxListTile(
                          title:
                              const Text("Foydalanuvchilarni o'chirish huquqi"),
                          value: permissions['canDeleteUsers'],
                          onChanged: (val) => setState(
                              () => permissions['canDeleteUsers'] = val!),
                        ),
                        CheckboxListTile(
                          title: const Text("Excel export qilish huquqi"),
                          value: permissions['canExportExcel'],
                          onChanged: (val) => setState(
                              () => permissions['canExportExcel'] = val!),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _createUser,
                          child: const Text("Foydalanuvchini yaratish",
                              style: TextStyle(fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
