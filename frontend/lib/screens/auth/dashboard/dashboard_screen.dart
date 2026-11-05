import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/custom_widgets.dart';
import '../../career/career_playbook_screen.dart';
import '../../help/help_center_screen.dart';
import '../../profile/profile_settings_screen.dart';
import '../login_screen.dart';
import 'job_matcher_screen.dart';
import 'learning_roadmap_screen.dart';
import 'mock_interview_screen.dart';
import 'resume_analyzer_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'CareerPilot User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.getProfile(widget.token);

      if (result['success'] == true && mounted) {
        setState(() {
          _userName = result['user']?['name'] ?? 'Professional';
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your current CareerPilot AI session?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.subtle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'CareerPilot',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: IconButton(
              onPressed: () => themeController.toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark ? Colors.amberAccent : AppColors.textSecondary,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
            ),
          ),
          // Help Center Button
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
              icon: Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              tooltip: 'Help & Knowledge Center',
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
            ),
          ),
          // Profile & Settings Button
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSettingsScreen(token: widget.token),
                  ),
                );
              },
              icon: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              tooltip: 'Profile & Settings',
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
            ),
          ),
          // Sign Out Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
              tooltip: 'Sign Out',
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting & Avatar Row (tappable to open profile)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileSettingsScreen(token: widget.token),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        boxShadow: isDark ? AppShadows.darkShadows : AppShadows.subtle,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoading ? 'Loading profile...' : '${_getGreeting()}, $_userName 👋',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ready to optimize your career path and prepare for top engineering roles?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: 'PRO',
                            icon: Icons.verified_rounded,
                            backgroundColor: AppColors.primarySoft,
                            textColor: AppColors.primary,
                            borderColor: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Hero Banner - Sleek Dark Aesthetic with Glass Badges
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -20,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 130,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      'Gemini AI Suite Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentEmerald.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: AppColors.accentEmerald, size: 8),
                                    SizedBox(width: 6),
                                    Text(
                                      'Models Ready',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Supercharge Your Job Search & Career Milestones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Analyze your PDF resume against real ATS filters, simulate realistic technical interview rounds, and match your skillset to specific target job posts.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildHeroStat('4 Specialized AI Modules'),
                              _buildHeroStat('Real-Time Interview Scoring'),
                              _buildHeroStat('Instant ATS Export'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Core AI Modules Section
                const SectionHeader(
                  title: 'Core AI Modules',
                  subtitle: 'Select a specialized tool to enhance your engineering portfolio',
                ),
                const SizedBox(height: 16),

                // Grid of Modules
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 640;
                    return GridView.count(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.6 : 2.05,
                      children: [
                        _FeatureCard(
                          title: 'Resume Analyzer',
                          subtitle: 'ATS score, strength highlights & keyword gap recommendations',
                          badge: 'ATS Scanner',
                          icon: Icons.description_rounded,
                          accentColor: AppColors.primary,
                          softColor: AppColors.primarySoft,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResumeAnalyzerScreen(),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Job Matcher',
                          subtitle: 'Compare your resume against any job description for match score',
                          badge: 'Target Fit',
                          icon: Icons.compare_arrows_rounded,
                          accentColor: AppColors.secondary,
                          softColor: AppColors.secondarySoft,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobMatcherScreen(),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Mock Interview AI',
                          subtitle: 'Practice role-specific Q&A with real-time feedback & grading',
                          badge: '5 Questions',
                          icon: Icons.record_voice_over_rounded,
                          accentColor: AppColors.accentAmber,
                          softColor: AppColors.accentAmberSoft,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MockInterviewScreen(),
                              ),
                            );
                          },
                        ),
                        _FeatureCard(
                          title: 'Learning Roadmap',
                          subtitle: 'Curated curriculum & milestones for your target tech stack',
                          badge: 'Milestones',
                          icon: Icons.alt_route_rounded,
                          accentColor: AppColors.accentEmerald,
                          softColor: AppColors.accentEmeraldSoft,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LearningRoadmapScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Career Playbooks & Tools Section
                const SectionHeader(
                  title: 'Career Resources & Tools',
                  subtitle: 'Blueprints, interactive interview checklists & help documentation',
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 1,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.45 : 2.6,
                      children: [
                        _SecondaryResourceCard(
                          title: 'Interview & ATS Playbook',
                          subtitle: 'STAR blueprints, action verbs & interactive 10-point readiness checklist',
                          badge: 'Checklist & Guides',
                          icon: Icons.menu_book_rounded,
                          accentColor: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CareerPlaybookScreen(),
                              ),
                            );
                          },
                        ),
                        _SecondaryResourceCard(
                          title: 'Help & Knowledge Center',
                          subtitle: 'Searchable FAQs, troubleshooting guides, live system health & feedback',
                          badge: '24/7 Support',
                          icon: Icons.help_center_rounded,
                          accentColor: AppColors.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpCenterScreen(),
                              ),
                            );
                          },
                        ),
                        _SecondaryResourceCard(
                          title: 'Profile & Preferences',
                          subtitle: 'Personalize target role, switch between Dark/Light modes & account settings',
                          badge: 'Appearance',
                          icon: Icons.tune_rounded,
                          accentColor: AppColors.accentAmber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileSettingsScreen(token: widget.token),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Career Advancement Tips
                const SectionHeader(
                  title: 'Career Advancement Insights',
                  subtitle: 'Key strategies verified by technical recruiters and hiring leads',
                ),
                const SizedBox(height: 14),

                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmberSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.accentAmber,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target 80%+ ATS Compatibility',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aim for a score above 80% on our Resume Analyzer before applying to prominent engineering roles to maximize interview callback rates.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildHeroStat(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final Color softColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.softColor,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: _isHovered ? 1.6 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : (isDark ? AppShadows.darkShadows : AppShadows.soft),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.softColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(widget.icon, color: widget.accentColor, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.softColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          widget.badge,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Launch Module',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 180),
                        offset: _isHovered ? const Offset(0.2, 0) : Offset.zero,
                        child: Icon(Icons.arrow_forward_rounded, size: 15, color: widget.accentColor),
                      ),
                    ],
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

class _SecondaryResourceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _SecondaryResourceCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SecondaryResourceCard> createState() => _SecondaryResourceCardState();
}

class _SecondaryResourceCardState extends State<_SecondaryResourceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.6)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : (isDark ? AppShadows.darkShadows : AppShadows.subtle),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(widget.icon, color: widget.accentColor, size: 20),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          widget.badge,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: widget.accentColor),
                    ],
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
