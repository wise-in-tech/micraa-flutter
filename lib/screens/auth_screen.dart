import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserModel) onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // true = تسجيل الدخول, false = إنشاء حساب
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_isLogin) {
      await _login();
    } else {
      await _register();
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'البريد الإلكتروني وكلمة المرور مطلوبان');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        final userData = result['user'];
        final user = UserModel(
          id: userData['userId'],
          name: userData['name'],
          email: userData['email'],
          role: userData['role'],
        );
        widget.onAuthSuccess(user);
      } else {
        setState(() => _error = result['error'] ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      setState(() => _error = 'خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      setState(() => _error = 'جميع الحقول مطلوبة');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Public registration always creates a STUDENT account (enforced backend-side);
      // there is no role field for the user to pick here.
      final result = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        final userData = result['user'];
        final user = UserModel(
          id: userData['userId'],
          name: userData['name'],
          email: userData['email'],
          role: userData['role'],
        );
        widget.onAuthSuccess(user);
      } else {
        setState(() => _error = result['error'] ?? 'فشل إنشاء الحساب');
      }
    } catch (e) {
      setState(() => _error = 'خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _authService.loginWithGoogle();

      if (!mounted) return;

      if (result['success']) {
        final userData = result['user'];
        final user = UserModel(
          id: userData['userId'],
          name: userData['name'],
          email: userData['email'],
          role: userData['role'],
        );
        widget.onAuthSuccess(user);
      } else if (result['canceled'] != true) {
        setState(() => _error = result['error'] ?? 'فشل تسجيل الدخول باستخدام Google');
      }
    } catch (e) {
      setState(() => _error = 'خطأ: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Logo / Titre
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(kPrimaryColor), Color(kPrimaryDarkColor)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(kAccentColor), width: 2),
                ),
                child: const Icon(Icons.mosque, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'مقرأة',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(kTextPrimaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(kTextSecondaryColor),
                ),
              ),
              const SizedBox(height: 36),

              // رسالة الخطأ
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(kDangerColor).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(kDangerColor)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(kDangerColor),
                      fontSize: 14,
                    ),
                  ),
                ),

              // حقل الاسم (عند إنشاء حساب فقط)
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: _fieldDecoration('الاسم الكامل'),
                  style: const TextStyle(color: Color(kTextPrimaryColor)),
                ),
                const SizedBox(height: 16),
              ],

              // البريد الإلكتروني
              TextField(
                controller: _emailController,
                decoration: _fieldDecoration('البريد الإلكتروني'),
                style: const TextStyle(color: Color(kTextPrimaryColor)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // كلمة المرور
              TextField(
                controller: _passwordController,
                decoration: _fieldDecoration('كلمة المرور'),
                style: const TextStyle(color: Color(kTextPrimaryColor)),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // لا يوجد اختيار للدور هنا: التسجيل العام ينشئ دائمًا حساب "طالب"
              // (راجع ticket-001). تُنشأ حسابات المعلمين عبر مسؤول النظام فقط.

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(kPrimaryColor),
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // تسجيل الدخول باستخدام Google (ينشئ حساب "طالب" عند أول دخول)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _googleLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(kSurfaceVariantColor)),
                    backgroundColor: const Color(kSurfaceColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(kAccentColor),
                    ),
                  ),
                  label: const Text(
                    'المتابعة باستخدام Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(kTextPrimaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // التبديل بين تسجيل الدخول وإنشاء حساب
              GestureDetector(
                onTap: _isLoading ? null : _toggleAuthMode,
                child: Text(
                  _isLogin
                      ? 'ليس لديك حساب؟ أنشئ حسابًا جديدًا'
                      : 'لديك حساب بالفعل؟ سجّل الدخول',
                  style: TextStyle(
                    color: _isLoading
                        ? Colors.white30
                        : const Color(kAccentColor),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(kTextSecondaryColor)),
        filled: true,
        fillColor: const Color(kSurfaceColor),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(kSurfaceVariantColor)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(kAccentColor)),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
