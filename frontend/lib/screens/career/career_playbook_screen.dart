import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/custom_widgets.dart';

class CareerPlaybookScreen extends StatefulWidget {
  const CareerPlaybookScreen({super.key});

  @override
  State<CareerPlaybookScreen> createState() => _CareerPlaybookScreenState();
}

class _CareerPlaybookScreenState extends State<CareerPlaybookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Set<String> _checkedItems = {};
  bool _isLoadingChecklist = true;

  final List<String> _checklistItems = [
    'Reviewed resume ATS score and addressed missing keywords',
    'Prepared 3 metric-backed projects with live demo / GitHub links',
    'Practiced at least 5 technical questions in Mock AI Interview',
    'Formatted STAR stories for 3 common behavioral questions',
    'Tested webcam, microphone, and quiet room lighting',
    'Researched company mission, recent product launches, and tech stack',
    'Prepared 3 thoughtful questions to ask the interviewer',
    'Reviewed core CS fundamentals (OOP, REST APIs, Git, Async programming)',
    'Checked PDF resume opens cleanly on desktop and mobile',
    'Had a good night of sleep and water bottle on desk',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChecklistProgress();
  }

  Future<void> _loadChecklistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('interview_checklist_items');
      if (saved != null) {
        setState(() {
          _checkedItems.addAll(saved);
        });
      }
    } catch (e) {
      debugPrint('Error loading checklist: $e');
    } finally {
      if (mounted) setState(() => _isLoadingChecklist = false);
    }
  }

  Future<void> _toggleChecklistItem(String item) async {
    setState(() {
      if (_checkedItems.contains(item)) {
        _checkedItems.remove(item);
      } else {
        _checkedItems.add(item);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('interview_checklist_items', _checkedItems.toList());
    } catch (e) {
      debugPrint('Error saving checklist: $e');
    }
  }

  double get _checklistProgress {
    if (_checklistItems.isEmpty) return 0;
    return _checkedItems.length / _checklistItems.length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Career Playbook & Guides'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amberAccent : AppColors.textSecondary,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => themeController.toggleTheme(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: isDark ? AppColors.darkTextPrimary : AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'ATS Playbook', icon: Icon(Icons.description_outlined, size: 20)),
            Tab(text: 'Interview Blueprint', icon: Icon(Icons.record_voice_over_outlined, size: 20)),
            Tab(text: 'Readiness Checklist', icon: Icon(Icons.checklist_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAtsPlaybookTab(isDark),
          _buildInterviewBlueprintTab(isDark),
          _buildChecklistTab(isDark),
        ],
      ),
    );
  }

  Widget _buildAtsPlaybookTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideCard(
                isDark: isDark,
                icon: Icons.auto_awesome_rounded,
                color: AppColors.primary,
                title: 'The 5 Rules of ATS Resume Optimization',
                description:
                    'Applicant Tracking Systems parse resumes into raw text fields. Following these guidelines ensures your resume reaches hiring managers with 90%+ parse accuracy.',
                items: [
                  '1. Use Standard Section Headers: Stick to "Summary", "Technical Skills", "Experience", "Projects", and "Education". Creative titles confuse parsers.',
                  '2. Quantify Your Achievements: Every bullet point should follow the Google formula: "Accomplished [X] as measured by [Y] by doing [Z]".',
                  '3. Match Keywords to Job Descriptions: If a job mentions "REST APIs", "State Management", or "CI/CD", use those exact terms rather than synonyms.',
                  '4. Single-Column Clean Hierarchy: Avoid complex tables, text boxes, headers/footers, and graphics that ATS scanners ignore.',
                  '5. Vector PDF Export: Always export directly from Google Docs, Word, or LaTeX into a standard PDF with selectable text.',
                ],
              ),
              const SizedBox(height: 18),
              _buildGuideCard(
                isDark: isDark,
                icon: Icons.bolt_rounded,
                color: AppColors.accentEmerald,
                title: 'High-Impact Action Verbs Cheat Sheet',
                description:
                    'Replace passive words like "worked on" or "responsible for" with strong, high-converting engineering verbs:',
                items: [
                  'Development: Architected, Engineered, Implemented, Deployed, Refactored, Containerized.',
                  'Performance: Optimized, Accelerated, Streamlined, Reduced latency by, Scaled.',
                  'Testing & Quality: Automated, Debugged, Validated, Audited, Hardened.',
                  'Leadership & Collaboration: Mentored, Coordinated, Spearheaded, Documented, Authored.',
                ],
              ),
              const SizedBox(height: 18),
              _buildGuideCard(
                isDark: isDark,
                icon: Icons.warning_amber_rounded,
                color: AppColors.error,
                title: 'Top ATS Red Flags to Avoid',
                description: 'Mistakes that lead to instant auto-rejection by ATS screening filters:',
                items: [
                  '• Saving as image or flat scanned PDF (ATS sees 0 characters).',
                  '• Embedding critical contact info inside headers or footers.',
                  '• Skill rating bars (e.g. "Python 4/5 stars" - ATS cannot evaluate graphical bars).',
                  '• Keyword stuffing in white font (triggers modern anti-spam filters).',
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewBlueprintTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideCard(
                isDark: isDark,
                icon: Icons.stars_rounded,
                color: AppColors.accentAmber,
                title: 'The STAR Method for Behavioral Questions',
                description:
                    'The gold standard framework used by FAANG & top tech companies to evaluate candidate past experience:',
                items: [
                  'S - Situation: Set the scene in 1-2 sentences. What was the company, project, or context?',
                  'T - Task: What was the specific challenge, bottleneck, or objective you faced?',
                  'A - Action: What technical decisions, tools, and steps did YOU personally take?',
                  'R - Result: What was the measurable outcome? (e.g., "Reduced app crash rate by 80% and launched on schedule").',
                ],
              ),
              const SizedBox(height: 18),
              _buildGuideCard(
                isDark: isDark,
                icon: Icons.code_rounded,
                color: AppColors.secondary,
                title: '4-Step Technical Problem Solving Protocol',
                description:
                    'Follow this structure when asked technical architecture or problem-solving questions:',
                items: [
                  '1. Clarify Requirements: Never code or explain immediately. Ask clarifying questions on inputs, scale, and edge cases.',
                  '2. Discuss Approaches & Tradeoffs: Mention the brute force option briefly, then propose the optimal pattern (e.g., time/space complexity).',
                  '3. Structure Solution: Break down the explanation into logical components (State, Service layer, Database, Error handling).',
                  '4. Review & Test: Walk through your explanation with sample inputs and mention testing strategies.',
                ],
              ),
              const SizedBox(height: 18),
              _buildGuideCard(
                isDark: isDark,
                icon: Icons.question_answer_rounded,
                color: AppColors.accentEmerald,
                title: 'Top 3 Questions to Ask the Interviewer',
                description: 'Show curiosity and maturity when asked "Do you have any questions for us?":',
                items: [
                  '• "What does the typical day-to-day workflow look like for an engineer on this team?"',
                  '• "What is the biggest technical challenge the engineering team is currently solving?"',
                  '• "How does the team approach code reviews, testing, and continuous deployment?"',
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistTab(bool isDark) {
    if (_isLoadingChecklist) {
      return const Center(child: CircularProgressIndicator());
    }

    final progressPct = (_checklistProgress * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Banner
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Interview Readiness Score',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '$progressPct%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _checklistProgress,
                        minHeight: 10,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                        color: progressPct >= 80 ? AppColors.accentEmerald : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_checkedItems.length} of ${_checklistItems.length} preparation tasks completed',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const SectionHeader(
                title: 'Pre-Interview Checklist',
                subtitle: 'Tick off each item before your interview to walk in fully confident',
              ),
              const SizedBox(height: 14),

              // Checklist Items
              ..._checklistItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isChecked = _checkedItems.contains(item);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: CheckboxListTile(
                      value: isChecked,
                      onChanged: (_) => _toggleChecklistItem(item),
                      activeColor: AppColors.accentEmerald,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isChecked ? FontWeight.w400 : FontWeight.w600,
                          decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                          color: isChecked
                              ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<String> items,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

