import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> courseData;
  final String uid;
  const CourseDetailScreen({super.key, required this.courseId, required this.courseData, required this.uid});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _checklist = [];
  List<String> _checklistDone = [];
  List<String> _sessionsDone = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final sessSnap = await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).collection('sessions').orderBy('order').get();
    final checkSnap = await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).collection('checklist').orderBy('order').get();
    final progressSnap = await FirebaseFirestore.instance.collection('user_progress').doc(widget.uid).get();
    final progressData = (progressSnap.data() as Map<String, dynamic>?) ?? {};
    final courseProgress = (progressData['courses'] as Map<String, dynamic>?)?[widget.courseId];

    setState(() {
      _sessions = sessSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _checklist = checkSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _checklistDone = List<String>.from(courseProgress?['checklistDone'] ?? []);
      _sessionsDone = List<String>.from(courseProgress?['sessionsDone'] ?? []);
      _loading = false;
    });
  }

  Future<void> _toggleChecklist(String itemId) async {
    final updated = [..._checklistDone];
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }
    setState(() => _checklistDone = updated);
    await FirebaseFirestore.instance.collection('user_progress').doc(widget.uid).set({
      'courses': {widget.courseId: {'checklistDone': updated, 'sessionsDone': _sessionsDone}}
    }, SetOptions(merge: true));
  }

  Future<void> _toggleSession(String sessionId) async {
    final updated = [..._sessionsDone];
    if (updated.contains(sessionId)) {
      updated.remove(sessionId);
    } else {
      updated.add(sessionId);
    }
    setState(() => _sessionsDone = updated);
    await FirebaseFirestore.instance.collection('user_progress').doc(widget.uid).set({
      'courses': {widget.courseId: {'checklistDone': _checklistDone, 'sessionsDone': updated}}
    }, SetOptions(merge: true));
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final colorHex = widget.courseData['colorHex'] as String? ?? '#0B2C6B';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    final doneCheck = _checklistDone.length;
    final totalCheck = _checklist.length;
    final doneSess = _sessionsDone.length;
    final totalSess = _sessions.length;
    final progress = (totalCheck + totalSess) == 0 ? 0.0 : ((doneCheck + doneSess) / (totalCheck + totalSess)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ── Header ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 12, 18, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text(widget.courseData['duration'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 52, width: 52,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(widget.courseData['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('👤 ${widget.courseData['instructor'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tabs ──
                  Container(
                    color: card,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: color,
                      unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                      indicatorColor: color,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [Tab(text: 'Overview'), Tab(text: 'Sessions'), Tab(text: 'Checklist')],
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ── OVERVIEW ──
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About this Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                              const SizedBox(height: 10),
                              Text(widget.courseData['description'] ?? '', style: TextStyle(fontSize: 15, height: 1.7, color: isDark ? Colors.white70 : Colors.black87)),
                              const SizedBox(height: 24),
                              Text('Course Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statBox('$totalSess', 'Sessions', Icons.video_library_rounded, color, card, isDark),
                                  const SizedBox(width: 12),
                                  _statBox('$doneSess', 'Completed', Icons.check_circle_rounded, Colors.green, card, isDark),
                                  const SizedBox(width: 12),
                                  _statBox('$totalCheck', 'Tasks', Icons.task_alt_rounded, Colors.orange, card, isDark),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text('Readiness Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8)]),
                                child: Column(
                                  children: [
                                    _progressRow('Sessions Done', totalSess == 0 ? 0 : doneSess / totalSess, color, isDark),
                                    const SizedBox(height: 14),
                                    _progressRow('Checklist Done', totalCheck == 0 ? 0 : doneCheck / totalCheck, Colors.orange, isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── SESSIONS ──
                        _sessions.isEmpty
                            ? Center(child: Text('No sessions yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(18),
                                itemCount: _sessions.length,
                                itemBuilder: (context, i) {
                                  final s = _sessions[i];
                                  final sessionId = s['id'] as String;
                                  final isDone = _sessionsDone.contains(sessionId);
                                  final type = s['type'] as String? ?? 'youtube';
                                  final url = s['url'] as String? ?? '';

                                  IconData typeIcon;
                                  Color typeColor;
                                  String typeLabel;
                                  switch (type) {
                                    case 'youtube':
                                      typeIcon = Icons.play_circle_rounded;
                                      typeColor = Colors.red;
                                      typeLabel = 'YouTube';
                                      break;
                                    case 'video':
                                      typeIcon = Icons.videocam_rounded;
                                      typeColor = Colors.blue;
                                      typeLabel = 'Video';
                                      break;
                                    case 'file':
                                      typeIcon = Icons.insert_drive_file_rounded;
                                      typeColor = Colors.orange;
                                      typeLabel = 'File';
                                      break;
                                    case 'image':
                                      typeIcon = Icons.image_rounded;
                                      typeColor = Colors.green;
                                      typeLabel = 'Image';
                                      break;
                                    default:
                                      typeIcon = Icons.link_rounded;
                                      typeColor = color;
                                      typeLabel = 'Link';
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(18),
                                      border: isDone ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5) : null,
                                      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))],
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 46, width: 46,
                                                decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                                                child: Icon(typeIcon, color: typeColor, size: 24),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s['title'] ?? '',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14.5,
                                                        color: isDone ? (isDark ? Colors.white38 : Colors.black45) : (isDark ? Colors.white : Colors.black87),
                                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                                          child: Text(typeLabel, style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600)),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text('⏱ ${s['duration'] ?? ''}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _toggleSession(sessionId),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 250),
                                                  height: 28, width: 28,
                                                  decoration: BoxDecoration(
                                                    color: isDone ? Colors.green : Colors.transparent,
                                                    border: Border.all(color: isDone ? Colors.green : (isDark ? Colors.white38 : Colors.black38), width: 2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (url.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: typeColor,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                onPressed: () => _openUrl(url),
                                                icon: Icon(type == 'youtube' ? Icons.play_arrow_rounded : type == 'file' ? Icons.download_rounded : Icons.open_in_new_rounded, size: 18),
                                                label: Text(
                                                  type == 'youtube' ? 'Watch on YouTube' : type == 'file' ? 'Open File' : type == 'image' ? 'View Image' : 'Open Link',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                        // ── CHECKLIST ──
                        _checklist.isEmpty
                            ? Center(child: Text('No checklist items', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text('Volunteer Readiness Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
                                        Text('$doneCheck/$totalCheck', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: totalCheck == 0 ? 0 : doneCheck / totalCheck,
                                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                                        valueColor: AlwaysStoppedAnimation(color),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      doneCheck == totalCheck && totalCheck > 0 ? '✅ You are ready to volunteer!' : '${totalCheck - doneCheck} tasks remaining',
                                      style: TextStyle(fontSize: 13, color: doneCheck == totalCheck && totalCheck > 0 ? Colors.green : (isDark ? Colors.white54 : Colors.black54)),
                                    ),
                                    const SizedBox(height: 20),
                                    ..._checklist.map((item) {
                                      final itemId = item['id'] as String;
                                      final isDone = _checklistDone.contains(itemId);
                                      return GestureDetector(
                                        onTap: () => _toggleChecklist(itemId),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: card,
                                            borderRadius: BorderRadius.circular(16),
                                            border: isDone
                                                ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5)
                                                : Border.all(color: isDark ? Colors.white12 : Colors.black12),
                                            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
                                          ),
                                          child: Row(
                                            children: [
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 250),
                                                height: 26, width: 26,
                                                decoration: BoxDecoration(
                                                  color: isDone ? Colors.green : Colors.transparent,
                                                  border: Border.all(color: isDone ? Colors.green : (isDark ? Colors.white38 : Colors.black38), width: 2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Text(
                                                  item['task'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDone ? (isDark ? Colors.white38 : Colors.black45) : (isDark ? Colors.white : Colors.black87),
                                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color, Color card, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, double value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
            Text('${(value * 100).round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: value, backgroundColor: isDark ? Colors.white12 : const Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation(color), minHeight: 7),
        ),
      ],
    );
  }
}