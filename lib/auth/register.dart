import 'package:flutter/material.dart';
import '../modules/services/auth_service.dart';
import '../modules/models/user_model.dart'; // UserRole enumi va kFaculties uchun shart

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // 🔒 Qat'iy nazorat: Rol har doim faqat talaba bo'ladi, dropdown o'chirildi
  final UserRole _fixedRole = UserRole.talaba;

  // 🎓 Talaba o'z fakultetini tanlashi shart
  String? _selectedFaculty;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    await AuthService.registerAndLoginUser(
      context: context,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _fixedRole, // 🎯 Faqat talaba roli uzatiladi
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      faculty: _selectedFaculty,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Talaba sifatida ro'yxatdan o'tish")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'To\'liq ismingiz',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Noto\'g\'ri email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Telefon raqam (Ixtiyoriy)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Parol', border: OutlineInputBorder()),
                validator: (v) => v == null || v.length < 6
                    ? 'Parol kamida 6 ta belgi bo\'lsin'
                    : null,
              ),
              const SizedBox(height: 16),

              // 🎓 Fakultetni tanlash
              DropdownButtonFormField<String>(
                value: _selectedFaculty,
                decoration: const InputDecoration(
                    labelText: 'Fakultetingizni tanlang',
                    border: OutlineInputBorder()),
                items: kFaculties
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedFaculty = val),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Fakultetni tanlang' : null,
              ),

              // 💡 DropdownButtonFormField (Rolni tanlash) qismi bu yerdan xavfsizlik uchun olib tashlangan.

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("Ro'yxatdan o'tish",
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
