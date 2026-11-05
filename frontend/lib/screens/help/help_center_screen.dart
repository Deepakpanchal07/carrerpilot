import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/custom_widgets.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Resume Analyzer',
    'Mock Interview',
    'Job Matcher',
    'Roadmaps',
    'Account & Setup',
  ];

  final List<Map<String, String>> _allFaqs = [
    {
      'category': 'Resume Analyzer',
      'question': 'How does the AI Resume Analyzer calculate the ATS score?',
      'answer':
          'The analyzer scans your PDF resume against real-world Applicant Tracking System (ATS) parsing algorithms. It evaluates keyword frequency, section structure (Summary, Skills, Experience, Education), metric-driven achievements, and readability to generate a score out of 100.',
    },
    {
      'category': 'Resume Analyzer',
      'question': 'How can I increase my resume score above 85/100?',
      'answer':
          '1. Include metric-driven bullet points (e.g. "Improved query performance by 40%").\n2. List explicit technical keywords matching your target role.\n3. Keep formatting clean—avoid complex multi-column tables, text boxes, or non-standard fonts.\n4. Ensure your contact details, GitHub, and LinkedIn links are clearly stated at the top.',
    },
    {
      'category': 'Resume Analyzer',
      'question': 'What file formats are accepted for resume upload?',
      'answer':
          'We accept standard PDF (.pdf) documents up to 5MB. Scanned image PDFs without selectable text may parse poorly; we recommend exporting directly from Google Docs, Word, or LaTeX into vector PDF.',
    },
    {
      'category': 'Mock Interview',
      'question': 'How does the Mock Interview simulation work?',
      'answer':
          'The interview conducts a 5-round interactive technical screening. For each question, you can submit your answer or tap "Show Answer" if you are stuck. Gemini AI evaluates your response, gives a score out of 10, highlights strengths & gaps, and displays an exemplary "Ideal / Correct Answer".',
    },
    {
      'category': 'Mock Interview',
      'question': 'Can I review past questions and model answers?',
      'answer':
          'Yes! Upon completing all 5 rounds, an Executive Summary screen displays expandable accordions for every question, allowing you to review your answers alongside the AI Ideal Answer with one-tap copy buttons.',
    },
    {
      'category': 'Job Matcher',
      'question': 'How does the Job Description Matcher work?',
      'answer':
          'Upload your resume PDF and paste the target job description. The engine cross-references required qualifications, frameworks, and responsibilities to calculate a match score, highlighting your matching strengths and pinpointing missing technical requirements.',
    },
    {
      'category': 'Roadmaps',
      'question': 'Are the learning roadmap milestones customizable?',
      'answer':
          'Yes! You can choose pre-built industry tracks (Flutter, Node.js, Python, Software Engineer) or use the AI Custom Roadmap Generator to generate a tailor-made plan based on your current skill level and daily study commitment.',
    },
    {
      'category': 'Account & Setup',
      'question': 'Why is my email verification OTP not arriving?',
      'answer':
          'Ensure your backend server is running and configured with a Google App Password in backend/.env. For development without email setup, check your backend terminal window where simulated verification codes are logged directly to the console.',
    },
    {
      'category': 'Account & Setup',
      'question': 'How do I switch between Dark and Light mode?',
      'answer':
          'You can switch themes instantly via the sun/moon icon button on your Dashboard or in Profile & Settings. Your preference is automatically remembered on this device.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    final query = _searchController.text.trim().toLowerCase();
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Send Us Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Encountered an issue or have a feature idea for CareerPilot AI? Let us know:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your feedback or question here...',
                  fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Thank you! Your feedback has been received.'),
                      ],
                    ),
                    backgroundColor: AppColors.accentEmerald,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Submit Feedback'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Help & FAQ Center'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: isDark ? AppColors.heroGradientDark : AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Knowledge Base & User Guidance',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'How can we help you succeed?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Explore answers on ATS optimization, interview scoring, job matching, and system troubleshooting.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search topics, questions, keywords...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              setState(() => _searchController.clear());
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 18),

                // Category Filter Pills
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: isDark ? AppColors.darkCard : AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // FAQ Accordions
                SectionHeader(
                  title: 'Frequently Asked Questions',
                  subtitle: '${_filteredFaqs.length} answers available in this category',
                ),
                const SizedBox(height: 14),

                if (_filteredFaqs.isEmpty) ...[
                  AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No matching questions found',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try a different keyword or reset your category filter.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ..._filteredFaqs.map((faq) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 18),
                          ),
                          title: Text(
                            faq['question']!,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                faq['answer']!,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.55,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 28),

                // System Status & Support Card
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.dns_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'System Status & Connectivity',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          StatusBadge.success(label: 'Operational', icon: Icons.check_circle_rounded),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStatusRow(
                        'Backend API Gateway',
                        ApiService.baseUrl,
                        true,
                        onTap: () => _showApiUrlDialog(context),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow('AI Intelligence Engine', 'Google Gemini 3.8 Flash', true),
                      const SizedBox(height: 8),
                      _buildStatusRow('Email Verification Service', 'Render HTTPS / Resend / SMTP', true),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _showFeedbackDialog,
                        icon: const Icon(Icons.feedback_outlined, size: 18),
                        label: const Text('Contact Support / Send Feedback'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
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

  void _showApiUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Backend URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your deployed Render backend URL or local development URL:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://careerpilot-backend.onrender.com/api',
                labelText: 'Backend API URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.saveCustomBaseUrl(null);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Reset to Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.saveCustomBaseUrl(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save URL'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String detail, bool isOnline, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_rounded, size: 13, color: AppColors.primary),
                ],
              ],
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.accentEmerald : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

