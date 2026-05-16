import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  void _showMessage(String message, bool isError) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFE53935) : const Color(0xFF16A34A),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void register() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty) {
      _showMessage("Please fill all fields", true);
      return;
    }
    if (password.text.trim().length < 6) {
      _showMessage("Password must be at least 6 characters", true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = credential.user;

      // حفظ الاسم في Firebase Auth
      await user?.updateDisplayName(name.text.trim());

      // حفظ بيانات اليوزر في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .set({
        'name': name.text.trim(),
        'email': email.text.trim(),
        'phone': '',
        'address': '',
        'photoBase64': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showMessage("Account created successfully!", false);

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = "Registration failed";
      switch (e.code) {
        case "email-already-in-use":
          errorMessage = "This email is already registered.";
          break;
        case "invalid-email":
          errorMessage = "The email address is not valid.";
          break;
        case "weak-password":
          errorMessage = "Password is too weak.";
          break;
        case "operation-not-allowed":
          errorMessage = "Registration is currently disabled.";
          break;
        default:
          errorMessage = e.message ?? "Registration failed";
      }
      _showMessage(errorMessage, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage("An error occurred. Please try again.", true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color primaryBlue = Color(0xFF0B2C6B);
    const Color primaryGreen = Color(0xFF16A34A);
    final Color fieldBg =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF6F8FC);
    final Color fieldText = isDark ? Colors.white : Colors.black87;
    final Color hintColor = isDark ? Colors.white54 : Colors.black45;
    final Color iconColor = isDark ? Colors.white54 : Colors.black45;
    final Color cardBg =
        isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final Color titleColor = isDark ? Colors.white : primaryBlue;
    final Color subtitleColor =
        isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B2C6B),
              Color(0xFF123C8E),
              Color(0xFF16A34A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 20),
              child: Column(
                children: [
                  // ── Icon ──
                  Container(
                    height: 95,
                    width: 95,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5),
                    ),
                    child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 44),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join the volunteer platform and start making impact",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  // ── Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 24,
                            offset: Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Register",
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: titleColor)),
                        const SizedBox(height: 8),
                        Text(
                          "Create your volunteer account to access campaigns, locations, and tasks.",
                          style: TextStyle(
                              fontSize: 14,
                              color: subtitleColor,
                              height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Name field
                        TextField(
                          controller: name,
                          style: TextStyle(color: fieldText),
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            labelStyle: TextStyle(color: hintColor),
                            hintText: "Enter your full name",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: iconColor),
                            filled: true,
                            fillColor: fieldBg,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                    color: primaryBlue, width: 1.4)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: fieldText),
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(color: hintColor),
                            hintText: "Enter your email",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: iconColor),
                            filled: true,
                            fillColor: fieldBg,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                    color: primaryBlue, width: 1.4)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextField(
                          controller: password,
                          obscureText: obscurePassword,
                          style: TextStyle(color: fieldText),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(color: hintColor),
                            hintText: "Create a password (min 6 chars)",
                            hintStyle: TextStyle(color: hintColor),
                            prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: iconColor),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() =>
                                  obscurePassword = !obscurePassword),
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: iconColor,
                              ),
                            ),
                            filled: true,
                            fillColor: fieldBg,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                    color: primaryGreen, width: 1.4)),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                  ),
                                  child: const Text("Create Account",
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold)),
                                ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account?",
                                style:
                                    TextStyle(color: subtitleColor)),
                            TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginScreen()),
                              ),
                              child: const Text("Login",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Volunteer Management System",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13,
                        letterSpacing: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}