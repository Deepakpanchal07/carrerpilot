import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/custom_widgets.dart';
import '../auth/login_screen.dart';
import '../career/career_playbook_screen.dart';
import '../help/help_center_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String token;

  const ProfileSettingsScreen({super.key, required this.token});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _userName = 'CareerPilot User';
  String _userEmail = 'user@example.com';
  String _targetRole = 'Flutter Developer';
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  final List<String> _roles = [
    'Flutter Developer',
    'Node.js Developer',
    'Python Developer',
    'Software Engineer',
    'Full Stack Engineer',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndPrefs();
  }

  Future<void> _loadProfileAndPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _targetRole = prefs.getString('user_target_role') ?? 'Flutter Developer';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      final result = await ApiService.getProfile(widget.token);
      if (result['success'] == true && mounted) {
        setState(() {
          _userName = result['user']?['name'] ?? 'CareerPilot User';
          _userEmail = result['user']?['email'] ?? 'user@example.com';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTargetRole(String role) async {
    setState(() => _targetRole = role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_target_role', role);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset All Local Data'),
        content: const Text(
          'This will clear saved roadmap progress and interview checklists on this device. Your account will remain active. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('interview_checklist_items');
    for (final role in ['Flutter_Developer', 'Node.js_Developer', 'Python_Developer', 'Software_Engineer']) {
      await prefs.remove('roadmap_progress_$role');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Local progress reset successfully'),
        backgroundColor: AppColors.accentEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your current session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.primary,
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoading ? 'Loading profile...' : _userName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userEmail,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            StatusBadge.primary(
                              label: _targetRole,
                              icon: Icons.code_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Theme Mode Section
                SectionHeader(
                  title: 'Appearance & Theme',
                  subtitle: 'Select your preferred visual style or sync with system',
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildThemeOption(
                        title: 'System Default',
                        subtitle: 'Automatically matches your device OS settings',
                        icon: Icons.brightness_auto_rounded,
                        mode: ThemeMode.system,
                      ),
                      const Divider(height: 20),
                      _buildThemeOption(
                        title: 'Light Mode',
                        subtitle: 'Crisp, high-contrast clean slate aesthetic',
                        icon: Icons.light_mode_rounded,
                        mode: ThemeMode.light,
                      ),
                      const Divider(height: 20),
                      _buildThemeOption(
                        title: 'Dark Mode',
                        subtitle: 'Deep obsidian & navy surfaces easy on the eyes',
                        icon: Icons.dark_mode_rounded,
                        mode: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Career Target Section
                SectionHeader(
                  title: 'Career Focus & Role',
                  subtitle: 'Tailors mock interview questions and roadmap milestones',
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Engineering Stack',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _targetRole,
                        decoration: InputDecoration(
                          fillColor: isDark ? AppColors.darkSurface : AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) _saveTargetRole(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Email Career Alerts & Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Receive weekly ATS updates and engineering tips', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Helpful Resources Links
                SectionHeader(
                  title: 'Help & Knowledge Center',
                  subtitle: 'Quick access to guides and FAQs',
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: const Text('Help Center & FAQs', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                        subtitle: const Text('Answers on ATS score, interview simulator, and setup', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                        },
                      ),
                      const Divider(height: 8),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.accentEmeraldSoft, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.auto_stories_rounded, color: AppColors.accentEmerald, size: 20),
                        ),
                        title: const Text('Career Playbook & Checklist', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                        subtitle: const Text('ATS rules, action verbs, and pre-interview checklist', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerPlaybookScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Danger / Account Actions
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.accentAmber),
                        title: const Text('Reset Local Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        subtitle: const Text('Clears checked roadmap milestones and interview checklist', style: TextStyle(fontSize: 12)),
                        onTap: _clearAllData,
                      ),
                      const Divider(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                        title: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
                        subtitle: const Text('End your session on this device', style: TextStyle(fontSize: 12)),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final isSelected = themeController.themeMode == mode;
    return InkWell(
      onTap: () => themeController.setThemeMode(mode),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

