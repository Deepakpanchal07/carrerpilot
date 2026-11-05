import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/default_roadmaps.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/custom_widgets.dart';

class LearningRoadmapScreen extends StatefulWidget {
  const LearningRoadmapScreen({super.key});

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  String selectedRole = 'Flutter Developer';
  String selectedSkillLevel = 'Beginner';
  int selectedDailyHours = 2;

  bool isGeneratingRoadmap = false;
  String? roadmapError;

  Map<String, dynamic>? aiRoadmap;
  final Map<String, List<Map<String, dynamic>>> roadmaps = defaultRoadmaps;

  final Map<String, Set<String>> completedTopics = {};
  bool isProgressLoading = true;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  String get progressKey =>
      'roadmap_progress_${selectedRole.replaceAll(' ', '_')}';

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      for (final role in roadmaps.keys) {
        final savedTopics =
            prefs.getStringList('roadmap_progress_${role.replaceAll(' ', '_')}');

        if (savedTopics != null) {
          completedTopics[role] = savedTopics.toSet();
        }
      }

      isProgressLoading = false;
    });
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      progressKey,
      completedTopics[selectedRole]?.toList() ?? [],
    );
  }

  List<Map<String, dynamic>> get currentRoadmap =>
      roadmaps[selectedRole] ?? [];

  int get totalTopics => currentRoadmap.fold<int>(
        0,
        (sum, phase) => sum + (phase['topics'] as List).length,
      );

  int get completedCount =>
      completedTopics[selectedRole]?.length ?? 0;

  double get progress =>
      totalTopics == 0 ? 0 : completedCount / totalTopics;

  Future<void> toggleTopic(String topic) async {
    setState(() {
      completedTopics.putIfAbsent(
        selectedRole,
        () => <String>{},
      );

      final completed = completedTopics[selectedRole]!;

      if (completed.contains(topic)) {
        completed.remove(topic);
      } else {
        completed.add(topic);
      }
    });

    await saveProgress();
  }

  Future<void> generateAiRoadmap() async {
    setState(() {
      isGeneratingRoadmap = true;
      roadmapError = null;
    });

    try {
      final response = await ApiService.generateLearningRoadmap(
        jobRole: selectedRole,
        skillLevel: selectedSkillLevel,
        dailyStudyHours: selectedDailyHours,
      );

      if (!mounted) return;

      setState(() {
        aiRoadmap = response['roadmap'] as Map<String, dynamic>;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        roadmapError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingRoadmap = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Learning Roadmap',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amberAccent : AppColors.textSecondary,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeController.toggleTheme(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isProgressLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark),
                        const SizedBox(height: 24),
                        _buildRoleSelector(isDark),
                        const SizedBox(height: 24),
                        _buildAiRoadmapForm(isDark),
                        const SizedBox(height: 24),
                        _buildProgressCard(isDark),

                        if (aiRoadmap != null) ...[
                          const SizedBox(height: 24),
                          _buildGeneratedRoadmap(isDark),
                        ],

                        const SizedBox(height: 28),
                        const SectionHeader(
                          title: 'Standard Curriculum & Milestones',
                          subtitle: 'Check off concepts as you master them to track advancement',
                        ),
                        const SizedBox(height: 16),
                        ...currentRoadmap.asMap().entries.map(
                              (entry) => _buildPhaseCard(
                                entry.value,
                                entry.key,
                                isDark,
                              ),
                            ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Master Your Engineering Career',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Follow structured, industry-aligned roadmaps to acquire in-demand skills step-by-step.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Technology Stack',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRole,
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: roadmaps.keys.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(
                  role,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (role) {
              if (role != null) {
                setState(() => selectedRole = role);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiRoadmapForm(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Custom Roadmap Generator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tailor learning pace according to your experience & available time',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Skill Level
          DropdownButtonFormField<String>(
            value: selectedSkillLevel,
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Current Proficiency',
              fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: ['Beginner', 'Intermediate', 'Advanced']
                .map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(
                        level,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedSkillLevel = value);
              }
            },
          ),
          const SizedBox(height: 16),

          // Daily Study Hours
          DropdownButtonFormField<int>(
            value: selectedDailyHours,
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Daily Study Commitment',
              fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [1, 2, 3, 4, 5, 6, 8]
                .map((hours) => DropdownMenuItem(
                      value: hours,
                      child: Text(
                        '$hours hours / day',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedDailyHours = value);
              }
            },
          ),
          const SizedBox(height: 20),

          // Generate Button
          GradientButton(
            onPressed: isGeneratingRoadmap ? null : generateAiRoadmap,
            text: isGeneratingRoadmap ? 'Synthesizing Roadmap...' : 'Generate AI Roadmap',
            icon: Icons.auto_awesome_rounded,
            isLoading: isGeneratingRoadmap,
          ),

          if (roadmapError != null) ...[
            const SizedBox(height: 14),
            Text(
              roadmapError!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratedRoadmap(bool isDark) {
    if (aiRoadmap == null) return const SizedBox.shrink();

    final phases = List<Map<String, dynamic>>.from(aiRoadmap!['phases'] ?? []);

    return AppCard(
      padding: const EdgeInsets.all(22),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.primary(
                label: 'Personalized AI Plan',
                icon: Icons.psychology_rounded,
              ),
              const Spacer(),
              if (aiRoadmap!['estimatedDuration'] != null)
                Text(
                  '${aiRoadmap!['estimatedDuration']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            aiRoadmap!['title'] ?? 'AI Learning Roadmap',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (aiRoadmap!['description'] != null && aiRoadmap!['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              aiRoadmap!['description'],
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),

          ...phases.asMap().entries.map((entry) {
            final phase = entry.value;
            final topics = List<String>.from(phase['topics'] ?? []);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: ExpansionTile(
                initiallyExpanded: entry.key == 0,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  phase['title'] ?? phase['phase'] ?? 'Phase',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${phase['phase'] ?? ''} • ${phase['duration'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                children: topics.map((topic) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accentEmerald,
                      size: 18,
                    ),
                    title: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Curriculum Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalTopics milestones completed',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              if (progress >= 1.0)
                const Row(
                  children: [
                    Icon(Icons.celebration_rounded, color: AppColors.accentAmber, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Curriculum Completed!',
                      style: TextStyle(
                        color: AppColors.accentAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase, int index, bool isDark) {
    final topics = List<String>.from(phase['topics']);
    final completed = completedTopics[selectedRole] ?? <String>{};
    final phaseCompleted = topics.where((t) => completed.contains(t)).length;
    final isAllCompleted = phaseCompleted == topics.length && topics.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(
            phase['title'],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${phase['phase']} • ${phase['duration']}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAllCompleted
                  ? (isDark ? AppColors.accentEmeraldSoftDark : AppColors.accentEmeraldSoft)
                  : (isDark ? AppColors.darkSurface : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$phaseCompleted / ${topics.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAllCompleted ? AppColors.accentEmerald : AppColors.primary,
              ),
            ),
          ),
          children: topics.map((topic) {
            final isCompleted = completed.contains(topic);

            return CheckboxListTile(
              value: isCompleted,
              onChanged: (_) => toggleTopic(topic),
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                topic,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCompleted ? FontWeight.w400 : FontWeight.w500,
                  color: isCompleted
                      ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
