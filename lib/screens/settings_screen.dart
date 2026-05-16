import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _darkMode = themeNotifier.value == ThemeMode.dark;
  }

  bool get _isAr => localeNotifier.value.languageCode == 'ar';

  void _changeDisplayName() {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = TextEditingController(text: _user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(_isAr ? 'تغيير الاسم' : 'Change Name', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: _isAr ? 'الاسم الكامل' : 'Full Name',
            filled: true,
            fillColor: isDark ? Colors.white10 : const Color(0xFFF6F8FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: primaryBlue))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              await _user?.updateDisplayName(newName);
              final uid = _user?.uid ?? '';
              if (uid.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(uid).set({'name': newName}, SetOptions(merge: true));
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isAr ? 'تم تحديث الاسم بنجاح ✅' : 'Name updated successfully ✅')));
                setState(() {});
              }
            },
            child: Text(_isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(_isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
        content: Text(_isAr ? 'سيتم إرسال رابط إعادة التعيين إلى:\n$email' : 'A reset email will be sent to:\n$email', style: const TextStyle(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: primaryBlue))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isAr ? 'تم إرسال البريد! تحقق من صندوق الوارد.' : 'Reset email sent!')));
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(_isAr ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
  }

  void _changeLanguage() {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(_isAr ? 'اختر اللغة' : 'Choose Language', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _langOption(ctx, setDlg, 'en', '🇺🇸', 'English', 'English language', primaryBlue, theme),
              const SizedBox(height: 10),
              _langOption(ctx, setDlg, 'ar', '🇪🇬', 'العربية', 'اللغة العربية', primaryBlue, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(BuildContext ctx, StateSetter setDlg, String code, String flag, String title, String sub, Color primaryBlue, ThemeData theme) {
    final selected = localeNotifier.value.languageCode == code;
    return GestureDetector(
      onTap: () {
        localeNotifier.value = Locale(code);
        setDlg(() {});
        setState(() {});
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(code == 'ar' ? 'تم تغيير اللغة إلى العربية' : 'Language changed to English')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? primaryBlue.withOpacity(0.08) : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? primaryBlue : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
              Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            if (selected) Icon(Icons.check_circle_rounded, color: primaryBlue),
          ],
        ),
      ),
    );
  }

  void _deleteAccount() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(_isAr ? 'حذف الحساب' : 'Delete Account', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_isAr ? 'هذا الإجراء دائم ولا يمكن التراجع عنه.' : 'This action is permanent and cannot be undone.', style: const TextStyle(fontSize: 14, height: 1.6)),
          const SizedBox(height: 14),
          TextField(
            controller: passCtrl,
            obscureText: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: _isAr ? 'كلمة المرور' : 'Password',
              filled: true,
              fillColor: isDark ? Colors.white10 : const Color(0xFFF6F8FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              try {
                final cred = EmailAuthProvider.credential(email: _user?.email ?? '', password: passCtrl.text.trim());
                await _user?.reauthenticateWithCredential(cred);
                await _user?.delete();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen()), (r) => false);
              } on FirebaseAuthException catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
              }
            },
            child: Text(_isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final displayName = _user?.displayName?.isNotEmpty == true ? _user!.displayName! : (_user?.email?.split('@')[0] ?? 'Volunteer');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]))),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: primaryBlue),
                      Text(_isAr ? 'الإعدادات' : 'Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryBlue)),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24)),
                      child: Row(children: [
                        CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.2), child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          Text(_user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    _section(_isAr ? 'الحساب' : 'Account', isDark),
                    _tile(icon: Icons.person_outline_rounded, title: _isAr ? 'تغيير الاسم' : 'Change Name', subtitle: displayName, color: primaryBlue, card: card, isDark: isDark, onTap: _changeDisplayName),
                    _tile(icon: Icons.lock_outline_rounded, title: _isAr ? 'تغيير كلمة المرور' : 'Change Password', subtitle: _isAr ? 'إرسال بريد إعادة التعيين' : 'Send reset email', color: primaryBlue, card: card, isDark: isDark, onTap: _changePassword),
                    const SizedBox(height: 16),
                    _section(_isAr ? 'التفضيلات' : 'Preferences', isDark),
                    _tile(
                      icon: Icons.language_rounded,
                      title: _isAr ? 'اللغة' : 'Language',
                      subtitle: _isAr ? 'العربية' : 'English',
                      color: primaryGreen, card: card, isDark: isDark, onTap: _changeLanguage,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(_isAr ? 'العربية' : 'English', style: TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    _switch(icon: Icons.dark_mode_outlined, title: _isAr ? 'الوضع الداكن' : 'Dark Mode', subtitle: _isAr ? 'تغيير مظهر التطبيق' : 'Switch app theme', color: const Color(0xFF7C3AED), card: card, isDark: isDark, value: _darkMode, onChanged: (v) { setState(() => _darkMode = v); themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light; }),
                    _switch(icon: Icons.notifications_outlined, title: _isAr ? 'الإشعارات' : 'Notifications', subtitle: _isAr ? 'تنبيهات المهام والحملات' : 'Task and campaign alerts', color: const Color(0xFFE16A2D), card: card, isDark: isDark, value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
                    const SizedBox(height: 16),
                    _section(_isAr ? 'منطقة الخطر' : 'Danger Zone', isDark),
                    _tile(icon: Icons.delete_forever_rounded, title: _isAr ? 'حذف الحساب' : 'Delete Account', subtitle: _isAr ? 'حذف حسابك نهائياً' : 'Permanently remove your account', color: Colors.red, card: card, isDark: isDark, onTap: _deleteAccount, isDestructive: true),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t, bool isDark) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black45, letterSpacing: 0.8)));

  Widget _tile({required IconData icon, required String title, required String subtitle, required Color color, required Color card, required bool isDark, required VoidCallback onTap, bool isDestructive = false, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))]),
      child: ListTile(
        onTap: onTap,
        leading: Container(height: 42, width: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black87))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 15, color: isDark ? Colors.white24 : Colors.black38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _switch({required IconData icon, required String title, required String subtitle, required Color color, required Color card, required bool isDark, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))]),
      child: ListTile(
        leading: Container(height: 42, width: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}