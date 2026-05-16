import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isAr = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryBlue, primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          ),
                          Text(isAr ? 'التواصل مع المنظمة' : 'Contact Organization', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ]),
                        const SizedBox(height: 16),
                        Container(
                          height: 80, width: 80,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
                          child: const Icon(Icons.business_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text(isAr ? 'صندوق مكافحة الإدمان' : 'Drug Addiction Control Fund', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(isAr ? 'نحن هنا للمساعدة' : 'We are here to help', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'وسائل التواصل' : 'Contact Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                          const SizedBox(height: 16),

                          // Phone
                          _ContactCard(
                            icon: Icons.phone_rounded,
                            color: Colors.green,
                            title: isAr ? 'الخط الساخن' : 'Hotline',
                            subtitle: '16023',
                            buttonLabel: isAr ? 'اتصل الآن' : 'Call Now',
                            card: card,
                            isDark: isDark,
                            onTap: () => _launch('tel:16023'),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          _ContactCard(
                            icon: Icons.email_rounded,
                            color: primaryBlue,
                            title: isAr ? 'البريد الإلكتروني' : 'Email',
                            subtitle: 'drugcontrol1@drugcontrol.org.eg',
                            buttonLabel: isAr ? 'إرسال بريد' : 'Send Email',
                            card: card,
                            isDark: isDark,
                            onTap: () => _launch('mailto:drugcontrol1@drugcontrol.org.eg'),
                          ),
                          const SizedBox(height: 24),

                          // Info card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: primaryBlue.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.info_outline_rounded, color: primaryBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(isAr ? 'معلومات مهمة' : 'Important Info', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 15)),
                                ]),
                                const SizedBox(height: 12),
                                _infoRow(isAr ? 'ساعات العمل: 24/7' : 'Working Hours: 24/7', Icons.access_time_rounded, isDark),
                                const SizedBox(height: 8),
                                _infoRow(isAr ? 'الخط الساخن مجاني تماماً' : 'Hotline is completely free', Icons.check_circle_rounded, isDark),
                                const SizedBox(height: 8),
                                _infoRow(isAr ? 'جميع المكالمات سرية' : 'All calls are confidential', Icons.lock_rounded, isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String text, IconData icon, bool isDark) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.green),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87))),
    ]);
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color card;
  final bool isDark;
  final VoidCallback onTap;

  const _ContactCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.buttonLabel, required this.card, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Container(height: 52, width: 52, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF101828))),
        ])),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          onPressed: onTap,
          child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ]),
    );
  }
}