import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
                  Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]))),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                        final allDocs = snap.data!.docs;
                        final docs = allDocs.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final assignedTo = (d['assignedTo'] as List?) ?? [];
                          return assignedTo.contains(uid);
                        }).toList();

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAr ? 'الكورسات التدريبية' : 'Training Courses', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryBlue)),
                              const SizedBox(height: 4),
                              Text(isAr ? 'طوّر مهاراتك التطوعية' : 'Improve your volunteer skills', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
                              const SizedBox(height: 22),

                              if (docs.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24)),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.school_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                                        const SizedBox(height: 12),
                                        Text(isAr ? 'لا توجد كورسات معيّنة بعد' : 'No courses assigned yet', style: TextStyle(fontSize: 16, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Text(isAr ? 'سيقوم المدير بتعيين كورسات لك قريباً' : 'Your admin will assign courses to you soon', style: TextStyle(fontSize: 13, color: isDark ? Colors.white24 : Colors.black26)),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                _OverallProgressBanner(uid: uid, docs: docs, primaryBlue: primaryBlue, primaryGreen: primaryGreen, isAr: isAr),
                                const SizedBox(height: 24),
                                Text(isAr ? 'كورساتك' : 'Your Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
                                const SizedBox(height: 14),
                                ...docs.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  return _CourseCard(courseId: doc.id, data: d, uid: uid, card: card, isDark: isDark, isAr: isAr);
                                }),
                              ],
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
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
}

class _OverallProgressBanner extends StatelessWidget {
  final String uid;
  final List<QueryDocumentSnapshot> docs;
  final Color primaryBlue;
  final Color primaryGreen;
  final bool isAr;
  const _OverallProgressBanner({required this.uid, required this.docs, required this.primaryBlue, required this.primaryGreen, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user_progress').doc(uid).snapshots(),
      builder: (context, snap) {
        final progressData = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        int doneChecklist = 0;
        for (final doc in docs) {
          final courseProgress = (progressData['courses'] as Map<String, dynamic>?)?[doc.id];
          doneChecklist += (courseProgress?['checklistDone'] as List?)?.length ?? 0;
        }
        final percent = docs.isEmpty ? 0.0 : (doneChecklist / (docs.length * 5)).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryBlue, primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'التقدم الإجمالي' : 'Overall Progress', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: percent, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 8),
                    ),
                    const SizedBox(height: 6),
                    Text('${(percent * 100).round()}% ${isAr ? "مكتمل — استمر!" : "Complete — Keep going!"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String courseId;
  final Map<String, dynamic> data;
  final String uid;
  final Color card;
  final bool isDark;
  final bool isAr;
  const _CourseCard({required this.courseId, required this.data, required this.uid, required this.card, required this.isDark, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final colorHex = data['colorHex'] as String? ?? '#0B2C6B';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user_progress').doc(uid).snapshots(),
      builder: (context, snap) {
        final progressData = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final courseProgress = (progressData['courses'] as Map<String, dynamic>?)?[courseId];
        final doneChecklist = (courseProgress?['checklistDone'] as List?)?.length ?? 0;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('courses').doc(courseId).collection('checklist').get(),
          builder: (context, checkSnap) {
            final totalChecklist = checkSnap.data?.docs.length ?? 1;
            final progress = (doneChecklist / totalChecklist).clamp(0.0, 1.0);
            final percent = (progress * 100).round();

            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: courseId, courseData: data, uid: uid))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(height: 52, width: 52, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.school_rounded, color: color)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: isDark ? Colors.white : const Color(0xFF101828))),
                              const SizedBox(height: 4),
                              Text('👤 ${data['instructor'] ?? ''}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
                              Text('⏱ ${data['duration'] ?? ''}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
                            ],
                          ),
                        ),
                        Icon(isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white30 : Colors.black26),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, backgroundColor: isDark ? Colors.white12 : const Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation(color), minHeight: 7))),
                        const SizedBox(width: 10),
                        Text('$percent%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: courseId, courseData: data, uid: uid))),
                        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(percent > 0 ? (isAr ? 'تابع الكورس' : 'Continue Course') : (isAr ? 'ابدأ الكورس' : 'Start Course'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}