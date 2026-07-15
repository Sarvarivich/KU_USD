import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modules/services/auth_service.dart';
import '../modules/models/user_model.dart'; // UserRole enumi va kFaculties uchun shart

// ─── RegisterScreen: talaba o'zini ro'yxatdan o'tkazadigan sahifa ─────
// Login sahifasi bilan bir xil vizual til (quyuq fon, glow doiralar,
// gradient kartalar) asosida, ammo o'ziga xos kreativ qo'shimchalar
// bilan: bosqichma-bosqich progress, parol kuchi indikatori, animatsiyalar.

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // 🔒 Qat'iy nazorat: Rol har doim faqat talaba bo'ladi, dropdown o'chirildi
  final UserRole _fixedRole = UserRole.talaba;

  // 🎓 Talaba o'z fakultetini tanlashi shart
  String? _selectedFaculty;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  double _passwordStrength = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Ranglar (login.dart bilan bir xil palitra)
  static const _bg = Color(0xFF0A0818);
  static const _card = Color(0xFF13102A);
  static const _purple = Color(0xFF6C5CE7);
  static const _violet = Color(0xFFa29bfe);
  static const _teal = Color(0xFF00CEC9);
  static const _pink = Color(0xFFfd79a8);
  static const _white = Colors.white;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final value = _passwordController.text;
    double strength = 0;
    if (value.length >= 6) strength += 0.34;
    if (value.length >= 10) strength += 0.16;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(value)) strength += 0.2;
    if (RegExp(r'[!@#\$&*~._-]').hasMatch(value)) strength += 0.1;
    setState(() => _passwordStrength = strength.clamp(0, 1));
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.34) return _pink;
    if (_passwordStrength < 0.7) return const Color(0xFFffb020);
    return _teal;
  }

  String get _strengthLabel {
    if (_passwordController.text.isEmpty) return '';
    if (_passwordStrength < 0.34) return 'Zaif';
    if (_passwordStrength < 0.7) return "O'rtacha";
    return 'Kuchli';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Parollar mos kelmadi"),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Davom etish uchun shartlarga rozilik bildiring"),
          backgroundColor: _pink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Fon glow orblari
          _GlowCircle(color: _teal, size: 260, top: -70, left: -60),
          _GlowCircle(color: _purple, size: 220, bottom: 60, right: -60),
          _GlowCircle(color: _pink, size: 150, top: 260, right: -30),

          SafeArea(
            child: Column(
              children: [
                // Orqaga qaytish
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: _white.withOpacity(0.7), size: 18),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_teal, _purple],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _teal.withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: _white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  'Talaba sifatida ro\'yxatdan o\'tish',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _white,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Yotoqxona tizimidan foydalanish uchun ma'lumotlaringizni to'ldiring",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _white.withOpacity(0.45),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Ro'yxatdan o'tish kartasi
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: _white.withOpacity(0.07),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 32,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionLabel(
                                        icon: Icons.badge_outlined,
                                        text: 'Shaxsiy ma\'lumotlar',
                                      ),
                                      const SizedBox(height: 14),

                                      _FieldLabel('To\'liq ismingiz'),
                                      const SizedBox(height: 8),
                                      _AuthField(
                                        controller: _nameController,
                                        hint: 'Ism Familiya',
                                        icon: Icons.person_outline_rounded,
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Ismni kiriting'
                                            : (v.trim().length < 3
                                                ? 'Ism kamida 3 harf bo\'lsin'
                                                : null),
                                      ),
                                      const SizedBox(height: 16),

                                      _FieldLabel('Email manzil'),
                                      const SizedBox(height: 8),
                                      _AuthField(
                                        controller: _emailController,
                                        hint: 'example@gmail.com',
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Email kiriting';
                                          }
                                          if (!v.contains('@') ||
                                              !v.contains('.')) {
                                            return 'Noto\'g\'ri email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      _FieldLabel('Telefon raqamingizni kiriting'),
                                      const SizedBox(height: 8),
                                      _AuthField(
                                        controller: _phoneController,
                                        hint: '+998 XX XXX XX XX',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: 16),

                                      _FieldLabel('Fakultetingizni tanlang'),
                                      const SizedBox(height: 8),
                                      _FacultyDropdown(
                                        value: _selectedFaculty,
                                        onChanged: (val) => setState(
                                            () => _selectedFaculty = val),
                                      ),

                                      const SizedBox(height: 22),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                                color:
                                                    _white.withOpacity(0.08)),
                                          ),
                                          const SizedBox(width: 10),
                                          _SectionLabel(
                                            icon: Icons.lock_outline_rounded,
                                            text: 'Xavfsizlik',
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Divider(
                                                color:
                                                    _white.withOpacity(0.08)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      _FieldLabel('Parol'),
                                      const SizedBox(height: 8),
                                      _AuthField(
                                        controller: _passwordController,
                                        hint: 'Kamida 6 ta belgi',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: _white.withOpacity(0.4),
                                            size: 18,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                        validator: (v) => v == null ||
                                                v.length < 6
                                            ? 'Parol kamida 6 ta belgi bo\'lsin'
                                            : null,
                                      ),
                                      const SizedBox(height: 10),

                                      // Parol kuchi indikatori
                                      AnimatedOpacity(
                                        opacity:
                                            _passwordController.text.isEmpty
                                                ? 0
                                                : 1,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: LayoutBuilder(
                                                builder:
                                                    (context, constraints) {
                                                  return Stack(
                                                    children: [
                                                      Container(
                                                        height: 5,
                                                        width: constraints
                                                            .maxWidth,
                                                        color: _white
                                                            .withOpacity(0.08),
                                                      ),
                                                      AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    250),
                                                        height: 5,
                                                        width: constraints
                                                                .maxWidth *
                                                            _passwordStrength,
                                                        color: _strengthColor,
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _strengthLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: _strengthColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      _FieldLabel('Parolni takrorlang'),
                                      const SizedBox(height: 8),
                                      _AuthField(
                                        controller: _confirmPasswordController,
                                        hint: 'Parolni qayta kiriting',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscureConfirmPassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: _white.withOpacity(0.4),
                                            size: 18,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Parolni takrorlang';
                                          }
                                          if (v.trim() !=
                                              _passwordController.text.trim()) {
                                            return 'Parollar mos kelmadi';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Shartlarga rozilik
                                      GestureDetector(
                                        onTap: () => setState(() =>
                                            _agreedToTerms = !_agreedToTerms),
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              width: 20,
                                              height: 20,
                                              margin:
                                                  const EdgeInsets.only(top: 1),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                gradient: _agreedToTerms
                                                    ? const LinearGradient(
                                                        colors: [
                                                          _teal,
                                                          _purple
                                                        ],
                                                      )
                                                    : null,
                                                color: _agreedToTerms
                                                    ? null
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: _agreedToTerms
                                                      ? Colors.transparent
                                                      : _white
                                                          .withOpacity(0.25),
                                                  width: 1.4,
                                                ),
                                              ),
                                              child: _agreedToTerms
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: _white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Foydalanish shartlari va maxfiylik siyosatiga roziman",
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  color:
                                                      _white.withOpacity(0.55),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      _RegisterButton(onTap: _register),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Allaqachon hisobingiz bormi? ",
                                      style: TextStyle(
                                        color: _white.withOpacity(0.4),
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: const Text(
                                        "Kirish",
                                        style: TextStyle(
                                          color: _violet,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Yordamchi widgetlar ────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double? top, bottom, left, right;

  const _GlowCircle({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: size,
              spreadRadius: size / 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.4)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.55),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00CEC9), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: const Color(0xFFfd79a8).withOpacity(0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFfd79a8), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFfd79a8), fontSize: 11),
      ),
    );
  }
}

class _FacultyDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FacultyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1B1836),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: Colors.white.withOpacity(0.4)),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Fakultetni tanlang',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.account_balance_outlined,
            color: Colors.white.withOpacity(0.4), size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00CEC9), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: const Color(0xFFfd79a8).withOpacity(0.7)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFfd79a8), fontSize: 11),
      ),
      items: kFaculties
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Fakultetni tanlang' : null,
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RegisterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00CEC9), Color(0xFF6C5CE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00CEC9).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Ro'yxatdan o'tish",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
