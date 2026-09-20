import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'classes_screen.dart';

class SelectUserScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const SelectUserScreen({
    super.key,
    this.onLogout,
  });

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  late AuthService _authService;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadUsers();
    });
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _authService.getUserData();
    if (userData != null) {
      setState(() {
        _currentUser = UserModel(
          id: userData['userId'],
          name: userData['name'],
          email: userData['email'],
          role: userData['role'],
        );
      });
    }
  }

  void _handleLogout() {
    _authService.logout();
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      appBar: AppBar(
        title: const Text('🎙️ Micraa'),
        backgroundColor: const Color(kPrimaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.loadUsers(),
          ),
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person),
                      title: Text(_currentUser!.name),
                      subtitle: Text(_currentUser!.email),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout, color: Color(0xFFC62828)),
                      title: Text(
                        'Déconnecter',
                        style: TextStyle(color: Color(0xFFC62828)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(kPrimaryColor),
            child: const Text(
              'Sélectionnez votre profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          if (state.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(kDangerColor)),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur de connexion',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => state.loadUsers(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('👨‍🏫 Professeurs'),
                  ...state.teachers.map((u) => _userCard(context, u)),
                  const SizedBox(height: 16),
                  _sectionTitle('👨‍🎓 Étudiants'),
                  ...state.students.map((u) => _userCard(context, u)),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _showCreateUserDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Créer un utilisateur'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _userCard(BuildContext context, UserModel user) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: user.isTeacher
                ? const Color(kPrimaryColor)
                : const Color(kAccentColor),
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(user.name),
          subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
          trailing: Chip(
            label: Text(
              user.role,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            backgroundColor: user.isTeacher
                ? const Color(kPrimaryColor)
                : const Color(kAccentColor),
            padding: EdgeInsets.zero,
          ),
          onTap: () {
            context.read<AppState>().selectUser(user);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ClassesScreen(),
              ),
            );
          },
        ),
      );

  void _showCreateUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'STUDENT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Créer un utilisateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'STUDENT', label: Text('Étudiant')),
                  ButtonSegment(value: 'TEACHER', label: Text('Professeur')),
                ],
                selected: {role},
                onSelectionChanged: (s) => setDialogState(() => role = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<AppState>().createUser(
                        nameCtrl.text.trim(),
                        emailCtrl.text.trim(),
                        role,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Utilisateur créé ✓')),
                    );
                  }
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
      ),
    );
  }
}
