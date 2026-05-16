import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get isAr => localeNotifier.value.languageCode == 'ar';

  Future<void> _login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      setState(() => _error = isAr ? 'يرجى ملء جميع الحقول' : 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _errorMsg(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailCtrl.text.trim();
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    if (email.isEmpty) {
      final emailResetCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isAr ? 'أدخل بريدك الإلكتروني' : 'Enter your email address',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: emailResetCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                labelStyle: TextStyle(color: primaryBlue),
                prefixIcon: Icon(Icons.email_rounded, color: primaryBlue, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (emailResetCtrl.text.isEmpty) return;
                Navigator.pop(context);
                await _sendReset(emailResetCtrl.text.trim());
              },
              child: Text(isAr ? 'إرسال' : 'Send'),
            ),
          ],
        ),
      );
    } else {
      await _sendReset(email);
    }
  }

  Future<void> _sendReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم إرسال رابط إعادة التعيين ✅' : 'Reset link sent ✅'),
          backgroundColor: Colors.green,
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_errorMsg(e.code)),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  String _errorMsg(String code) {
    if (isAr) {
      switch (code) {
        case 'user-not-found': return 'البريد الإلكتروني غير مسجل';
        case 'wrong-password': return 'كلمة المرور غير صحيحة';
        case 'invalid-email': return 'البريد الإلكتروني غير صالح';
        case 'too-many-requests': return 'محاولات كثيرة، حاول لاحقاً';
        case 'invalid-credential': return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        default: return 'حدث خطأ، حاول مرة أخرى';
      }
    } else {
      switch (code) {
        case 'user-not-found': return 'Email not registered';
        case 'wrong-password': return 'Wrong password';
        case 'invalid-email': return 'Invalid email';
        case 'too-many-requests': return 'Too many attempts, try later';
        case 'invalid-credential': return 'Invalid email or password';
        default: return 'An error occurred, try again';
      }
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Center(child: Column(children: [
                      Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [primaryBlue, primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 48),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('KEEP IT CLEAN', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(isAr ? 'نظام إدارة المتطوعين' : 'Volunteer Management System',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
                    ])),
                    const SizedBox(height: 32),
                    // Form
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 6))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(isAr ? 'تسجيل الدخول' : 'Sign In',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF101828))),
                        const SizedBox(height: 4),
                        Text(isAr ? 'مرحباً بعودتك!' : 'Welcome back!',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                            labelStyle: TextStyle(color: primaryBlue),
                            prefixIcon: Icon(Icons.email_rounded, color: primaryBlue, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: primaryBlue, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passCtrl,
                          obscureText: _obscure,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: isAr ? 'كلمة المرور' : 'Password',
                            labelStyle: TextStyle(color: primaryBlue),
                            prefixIcon: Icon(Icons.lock_rounded, color: primaryBlue, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: isDark ? Colors.white38 : Colors.black38, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: primaryBlue, width: 2)),
                          ),
                        ),
                        Align(
                          alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text(isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                            ]),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(isAr ? 'دخول' : 'Sign In',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Coming Soon badge
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.fingerprint_rounded, color: primaryBlue.withOpacity(0.4), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'الدخول بالبصمة — قريباً' : 'Fingerprint Login — Coming Soon',
                            style: TextStyle(color: primaryBlue.withOpacity(0.4), fontSize: 12),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(isAr ? 'ليس لديك حساب؟ ' : "Don't have an account? ",
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                        child: Text(isAr ? 'إنشاء حساب' : 'Sign Up',
                            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}