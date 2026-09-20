import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/live_class_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser!;

    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes Classes', style: TextStyle(fontSize: 16)),
            Text(
              user.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        backgroundColor: const Color(kPrimaryColor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                context.read<AppState>().logout();
              }
              widget.onLogout?.call();
            },
          ),
        ],
      ),
      floatingActionButton: user.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateClassDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle Classe'),
              backgroundColor: const Color(kPrimaryColor),
            )
          : null,
      body: _buildBody(user.isTeacher),
    );
  }

  Widget _buildBody(bool isTeacher) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(kDangerColor)),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadClasses, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              isTeacher
                  ? 'Aucune classe. Créez-en une !'
                  : 'Aucune classe disponible.',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (_, i) => _classCard(context, _classes[i], isTeacher),
      ),
    );
  }

  Widget _classCard(BuildContext context, LiveClassModel lc, bool isTeacher) {
    final statusColor = lc.isLive
        ? const Color(kSuccessColor)
        : lc.isScheduled
            ? const Color(kPrimaryColor)
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + badge status
            Row(
              children: [
                Expanded(
                  child: Text(
                    lc.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
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
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        lc.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prof: ${lc.teacherName}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),

            // Actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Professeur : démarrer ou terminer
                if (isTeacher && lc.isScheduled)
                  ElevatedButton.icon(
                    onPressed: () => _startClass(context, lc),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Démarrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kSuccessColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (isTeacher && lc.isLive) ...[
                  ElevatedButton.icon(
                    onPressed: () => _joinClass(context, lc),
                    icon: const Icon(Icons.mic, size: 18),
                    label: const Text('Rejoindre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kPrimaryColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _endClass(context, lc),
                    icon: const Icon(Icons.stop, size: 18, color: Color(kDangerColor)),
                    label: const Text('Terminer', style: TextStyle(color: Color(kDangerColor))),
                  ),
                ],
                // Étudiant : rejoindre si LIVE
                if (!isTeacher && lc.isLive)
                  ElevatedButton.icon(
                    onPressed: () => _joinClass(context, lc),
                    icon: const Icon(Icons.headphones, size: 18),
                    label: const Text('Rejoindre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(kPrimaryColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (!isTeacher && !lc.isLive)
                  Text(
                    lc.isEnded ? 'Classe terminée' : 'En attente...',
                    style: const TextStyle(color: Colors.grey),
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
          const SnackBar(content: Text('Classe démarrée ✓')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
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
        _loadClasses();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur join : $e')),
        );
      }
    }
  }

  Future<void> _endClass(BuildContext context, LiveClassModel lc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminer la classe ?'),
        content: const Text('Cette action terminera la session pour tous les participants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(kDangerColor)),
            child: const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final user = context.read<AppState>().currentUser!;
    final api = context.read<AppState>().apiService;
    try {
      await api.endLiveClass(lc.id, user.id);
      _loadClasses();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  void _showCreateClassDialog(BuildContext context) {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle Classe'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre de la classe',
            hintText: 'Ex: Cours de Math - Chapitre 3',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
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
                    SnackBar(content: Text('Erreur : $e')),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
