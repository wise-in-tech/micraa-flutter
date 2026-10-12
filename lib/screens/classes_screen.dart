import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/live_class_model.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../widgets/islamic_pattern_header.dart';
import 'live_room_screen.dart';

class ClassesScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ClassesScreen({super.key, this.onLogout});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<LiveClassModel> _classes = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final user = context.read<AppState>().currentUser!;
    final api = context.read<AppState>().apiService;
    setState(() { _isLoading = true; _error = null; });
    try {
      final classes = await api.getLiveClassesForUser(user);
      setState(() => _classes = classes);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    if (!mounted) return;
    context.read<AppState>().logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser!;

    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      appBar: AppBar(
        title: const Text('مقرأة'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _showCreateClassDialog(context);
                  break;
                case 'refresh':
                  _loadClasses();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (user.isTeacher)
                const PopupMenuItem(
                  value: 'new',
                  child: ListTile(
                    leading: Icon(Icons.add_circle_outline),
                    title: Text('حلقة جديدة'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('تحديث'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Color(kDangerColor)),
                  title: Text('تسجيل الخروج', style: TextStyle(color: Color(kDangerColor))),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          IslamicPatternHeader(
            height: 120,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: const Color(kAccentColor), width: 1.5),
                  ),
                  child: Icon(
                    user.isTeacher ? Icons.school : Icons.menu_book,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السلام عليكم، ${user.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isTeacher ? 'حلقاتك التعليمية' : 'حلقاتك المتاحة',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(user.isTeacher)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isTeacher) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(kPrimaryColor)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(kDangerColor)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(kTextSecondaryColor)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadClasses, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque, size: 64, color: Color(kTextSecondaryColor)),
            const SizedBox(height: 12),
            Text(
              isTeacher ? 'لا توجد حلقات. أنشئ حلقة جديدة!' : 'لا توجد حلقات متاحة حاليًا.',
              style: const TextStyle(color: Color(kTextSecondaryColor), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      color: const Color(kPrimaryColor),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (_, i) => _classCard(context, _classes[i], isTeacher),
      ),
    );
  }

  String _statusLabel(LiveClassModel lc) {
    if (lc.isLive) return 'جارية';
    if (lc.isScheduled) return 'مجدولة';
    return 'منتهية';
  }

  Widget _classCard(BuildContext context, LiveClassModel lc, bool isTeacher) {
    final statusColor = lc.isLive
        ? const Color(kSuccessColor)
        : lc.isScheduled
            ? const Color(kAccentColor)
            : const Color(kTextSecondaryColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + شارة الحالة
            Row(
              children: [
                const Icon(Icons.menu_book, size: 18, color: Color(kAccentColor)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lc.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(kTextPrimaryColor),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lc.isLive)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                      Text(
                        _statusLabel(lc),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.school, size: 15, color: Color(kTextSecondaryColor)),
                const SizedBox(width: 6),
                Text(
                  'المعلم: ${lc.teacherName}',
                  style: const TextStyle(color: Color(kTextSecondaryColor), fontSize: 13),
                ),
              ],
            ),

            // الإجراءات
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isTeacher && lc.isScheduled)
                  ElevatedButton.icon(
                    onPressed: () => _startClass(context, lc),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('بدء'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kSuccessColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (isTeacher && lc.isLive) ...[
                  ElevatedButton.icon(
                    onPressed: () => _joinClass(context, lc),
                    icon: const Icon(Icons.auto_stories, size: 18),
                    label: const Text('انضم الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kPrimaryColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _endClass(context, lc),
                    icon: const Icon(Icons.stop, size: 18, color: Color(kDangerColor)),
                    label: const Text('إنهاء', style: TextStyle(color: Color(kDangerColor))),
                  ),
                ],
                if (!isTeacher && lc.isLive)
                  ElevatedButton.icon(
                    onPressed: () => _joinClass(context, lc),
                    icon: const Icon(Icons.auto_stories, size: 18),
                    label: const Text('انضم الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kPrimaryColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (!isTeacher && !lc.isLive)
                  Text(
                    lc.isEnded ? 'انتهت الحلقة' : 'في الانتظار...',
                    style: const TextStyle(color: Color(kTextSecondaryColor)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startClass(BuildContext context, LiveClassModel lc) async {
    final user = context.read<AppState>().currentUser!;
    final api = context.read<AppState>().apiService;
    try {
      await api.startLiveClass(lc.id, user.id);
      _loadClasses();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم بدء الحلقة ✓')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _joinClass(BuildContext context, LiveClassModel lc) async {
    final user = context.read<AppState>().currentUser!;
    final api = context.read<AppState>().apiService;
    try {
      final joinResp = await api.joinLiveClass(lc.id, user.id);
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LiveRoomScreen(
              liveClass: lc,
              joinResponse: joinResp,
              currentUser: user,
            ),
          ),
        );
        if (context.mounted) _loadClasses();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الانضمام: $e')),
        );
      }
    }
  }

  Future<void> _endClass(BuildContext context, LiveClassModel lc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الحلقة؟'),
        content: const Text('سينهي هذا الإجراء الجلسة لجميع المشاركين.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(kDangerColor)),
            child: const Text('إنهاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    final user = context.read<AppState>().currentUser!;
    final api = context.read<AppState>().apiService;
    try {
      await api.endLiveClass(lc.id, user.id);
      _loadClasses();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  void _showCreateClassDialog(BuildContext context) {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حلقة جديدة'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان الحلقة',
            hintText: 'مثال: حفظ سورة البقرة',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = context.read<AppState>().currentUser!;
              final api = context.read<AppState>().apiService;
              try {
                await api.createLiveClass(
                  title: titleCtrl.text.trim(),
                  teacherId: user.id,
                );
                _loadClasses();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }
}
