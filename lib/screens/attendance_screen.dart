import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

// ─── Volunteer Attendance Screen ───
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final primaryGreen = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final card = theme.cardColor;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, primaryGreen]))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded), color: primaryBlue),
                    Text(isAr ? 'الحضور والغياب' : 'Attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('campaigns')
                      .where('assignedTo', arrayContains: uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                            const SizedBox(height: 12),
                            Text(isAr ? 'لا توجد حملات معيّنة' : 'No campaigns assigned', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final campaignId = docs[i].id;
                        final attendees = List<String>.from(d['attendees'] ?? []);
                        final hasAttended = attendees.contains(uid);

                        final dateTs = d['date'] as Timestamp?;
                        String dateStr = '';
                        if (dateTs != null) {
                          final dt = dateTs.toDate();
                          dateStr = '${dt.day}/${dt.month}/${dt.year}';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasAttended ? primaryGreen.withOpacity(0.08) : card,
                            borderRadius: BorderRadius.circular(20),
                            border: hasAttended ? Border.all(color: primaryGreen.withOpacity(0.3)) : null,
                            boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 48, width: 48,
                                    decoration: BoxDecoration(
                                      color: (hasAttended ? primaryGreen : primaryBlue).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.campaign_rounded, color: hasAttended ? primaryGreen : primaryBlue, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF101828))),
                                        if ((d['location'] ?? '').isNotEmpty)
                                          Text('📍 ${d['location']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                                        if (dateStr.isNotEmpty)
                                          Text('📅 $dateStr', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: (hasAttended ? primaryGreen : Colors.orange).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      hasAttended ? (isAr ? 'حضر' : 'Present') : (isAr ? 'غائب' : 'Absent'),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasAttended ? primaryGreen : Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.people_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                                  const SizedBox(width: 4),
                                  Text('${attendees.length} ${isAr ? "حضروا" : "attended"}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (!hasAttended)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('campaigns').doc(campaignId).update({
                                        'attendees': FieldValue.arrayUnion([uid]),
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isAr ? 'تم تسجيل حضورك ✅' : 'Attendance recorded ✅'), backgroundColor: primaryGreen),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                                    label: Text(isAr ? 'تسجيل الحضور' : 'Mark Present', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryGreen,
                                      side: BorderSide(color: primaryGreen.withOpacity(0.4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: null,
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: Text(isAr ? 'تم تسجيل الحضور' : 'Attendance Recorded'),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Admin Campaign Management ───
class AdminCampaignsTab extends StatelessWidget {
  const AdminCampaignsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isAr = localeNotifier.value.languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryBlue,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCampaignEditScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(isAr ? 'حملة جديدة' : 'New Campaign', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Text(isAr ? 'إدارة الحملات' : 'Campaigns Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('campaigns').orderBy('date', descending: false).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(child: Text(isAr ? 'لا توجد حملات بعد' : 'No campaigns yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final attendees = (d['attendees'] as List?)?.length ?? 0;
                      final assigned = (d['assignedTo'] as List?)?.length ?? 0;
                      final dateTs = d['date'] as Timestamp?;
                      String dateStr = '';
                      if (dateTs != null) {
                        final dt = dateTs.toDate();
                        dateStr = '${dt.day}/${dt.month}/${dt.year}';
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 48, width: 48,
                              decoration: BoxDecoration(color: primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.campaign_rounded, color: primaryBlue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? Colors.white : const Color(0xFF101828))),
                                  if (dateStr.isNotEmpty) Text('📅 $dateStr', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                                  Row(
                                    children: [
                                      Icon(Icons.people_rounded, size: 12, color: primaryBlue),
                                      const SizedBox(width: 4),
                                      Text('$attendees/$assigned ${isAr ? "حضروا" : "attended"}', style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_rounded, color: primaryBlue, size: 20),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCampaignEditScreen(campaignId: docs[i].id, campaignData: d))),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => FirebaseFirestore.instance.collection('campaigns').doc(docs[i].id).delete(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCampaignEditScreen extends StatefulWidget {
  final String? campaignId;
  final Map<String, dynamic>? campaignData;
  const AdminCampaignEditScreen({super.key, this.campaignId, this.campaignData});

  @override
  State<AdminCampaignEditScreen> createState() => _AdminCampaignEditScreenState();
}

class _AdminCampaignEditScreenState extends State<AdminCampaignEditScreen> {
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime? _date;
  List<Map<String, dynamic>> _volunteers = [];
  List<String> _assignedTo = [];
  bool _saving = false;
  final isAr = localeNotifier.value.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    if (widget.campaignData != null) {
      final d = widget.campaignData!;
      titleCtrl.text = d['title'] ?? '';
      locationCtrl.text = d['location'] ?? '';
      descCtrl.text = d['description'] ?? '';
      _assignedTo = List<String>.from(d['assignedTo'] ?? []);
      final ts = d['date'] as Timestamp?;
      if (ts != null) _date = ts.toDate();
    }
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    setState(() => _volunteers = snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'title': titleCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'date': _date != null ? Timestamp.fromDate(_date!) : null,
      'assignedTo': _assignedTo,
      'attendees': widget.campaignData?['attendees'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (widget.campaignId == null) {
      await FirebaseFirestore.instance.collection('campaigns').add(data);
    } else {
      await FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).update(data);
    }
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    titleCtrl.dispose(); locationCtrl.dispose(); descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBlue = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: Text(widget.campaignId == null ? (isAr ? 'حملة جديدة' : 'New Campaign') : (isAr ? 'تعديل الحملة' : 'Edit Campaign'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(titleCtrl, isAr ? 'عنوان الحملة' : 'Campaign Title', Icons.campaign_rounded, isDark, primaryBlue),
            const SizedBox(height: 14),
            _field(locationCtrl, isAr ? 'الموقع' : 'Location', Icons.location_on_rounded, isDark, primaryBlue),
            const SizedBox(height: 14),
            _field(descCtrl, isAr ? 'الوصف' : 'Description', Icons.description_rounded, isDark, primaryBlue, maxLines: 3),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white38 : Colors.black26), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: primaryBlue, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _date == null ? (isAr ? 'اختر التاريخ' : 'Select Date') : '${_date!.day}/${_date!.month}/${_date!.year}',
                      style: TextStyle(color: _date == null ? (isDark ? Colors.white38 : Colors.black38) : (isDark ? Colors.white : Colors.black87)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(isAr ? 'تعيين المتطوعين' : 'Assign Volunteers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
            const SizedBox(height: 10),
            ..._volunteers.map((v) {
              final uid = v['uid'] as String;
              final isAssigned = _assignedTo.contains(uid);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isAssigned ? primaryBlue.withOpacity(0.08) : theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: isAssigned ? Border.all(color: primaryBlue.withOpacity(0.3)) : null,
                ),
                child: CheckboxListTile(
                  value: isAssigned,
                  activeColor: primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) { _assignedTo.add(uid); } else { _assignedTo.remove(uid); }
                    });
                  },
                  title: Text(v['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF101828))),
                  subtitle: Text(v['phone'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                  secondary: CircleAvatar(
                    backgroundColor: primaryBlue.withOpacity(0.15),
                    child: Text((v['name'] ?? 'V')[0].toUpperCase(), style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool isDark, Color color, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        prefixIcon: Icon(icon, color: color, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}