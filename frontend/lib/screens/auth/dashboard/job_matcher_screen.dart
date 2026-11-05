import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/custom_widgets.dart';

class JobMatcherScreen extends StatefulWidget {
  const JobMatcherScreen({super.key});

  @override
  State<JobMatcherScreen> createState() => _JobMatcherScreenState();
}

class _JobMatcherScreenState extends State<JobMatcherScreen> {
  final _jobDescriptionController = TextEditingController();

  PlatformFile? _selectedResume;
  bool _isPicking = false;
  bool _isLoading = false;
  String? _matchingResult;
  String? _errorMessage;

  Future<void> _pickResume() async {
    try {
      setState(() => _isPicking = true);

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'File size exceeds the 5MB limit. Please choose a smaller PDF.';
          });
          return;
        }

        setState(() {
          _selectedResume = file;
          _matchingResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to select PDF: $e';
      });
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeResume() {
    setState(() {
      _selectedResume = null;
      _matchingResult = null;
      _errorMessage = null;
    });
  }

  Future<void> _matchResume() async {
    final jobDescription = _jobDescriptionController.text.trim();

    if (_selectedResume == null || _selectedResume!.bytes == null) {
      setState(() {
        _errorMessage = 'Please select your resume PDF first.';
      });
      return;
    }

    if (_selectedResume!.size > 5 * 1024 * 1024) {
      setState(() {
        _errorMessage = 'File size exceeds the 5MB limit. Please choose a smaller PDF.';
      });
      return;
    }

    if (jobDescription.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or paste the target job description.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _matchingResult = null;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.matchResumeWithJob(
        fileBytes: _selectedResume!.bytes!,
        fileName: _selectedResume!.name,
        jobDescription: jobDescription,
      );

      if (!mounted) return;

      setState(() {
        _matchingResult = response['data']?['matchingResult']?.toString() ??
            'No matching result received.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Job Description Matcher',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: const Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Job Match Engine',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Compare your profile against specific job posts to uncover alignment & technical gaps',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Step 1: Upload Resume
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Upload Your Resume',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (_selectedResume == null) ...[
                        OutlinedButton.icon(
                          onPressed: _isPicking || _isLoading ? null : _pickResume,
                          icon: _isPicking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file_rounded, size: 20),
                          label: Text(_isPicking ? 'Selecting...' : 'Select Resume PDF (up to 5MB)'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentRoseSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: AppColors.accentRose,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedResume!.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: _isLoading ? null : _removeResume,
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Step 2: Paste Job Description
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: AppColors.cyanGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Target Job Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (_jobDescriptionController.text.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _jobDescriptionController.clear();
                                });
                              },
                              child: const Text('Clear Text'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _jobDescriptionController,
                        maxLines: 8,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste the job posting requirements, tech stack, and qualifications here...',
                          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.border,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accentRoseSoftDark : AppColors.accentRoseSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Action Button
                GradientButton(
                  onPressed: _isLoading ? null : _matchResume,
                  text: _isLoading ? 'Analyzing Match with Gemini AI...' : 'Match My Resume with Job',
                  icon: Icons.compare_arrows_rounded,
                  isLoading: _isLoading,
                ),

                // Match Report
                if (_matchingResult != null) ...[
                  const SizedBox(height: 36),
                  Text(
                    'AI Job Match Evaluation',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border(
                        left: const BorderSide(color: AppColors.secondary, width: 4.5),
                        top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                        right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                        bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.secondarySoftDark : AppColors.secondarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Compatibility Breakdown',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          _matchingResult!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
