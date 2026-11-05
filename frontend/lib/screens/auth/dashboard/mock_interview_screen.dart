import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../../widgets/custom_widgets.dart';

class InterviewFeedback {
  final double score;
  final String whatWasCorrect;
  final String whatNeedsImprovement;
  final String idealAnswer;
  final String rawText;

  InterviewFeedback({
    required this.score,
    required this.whatWasCorrect,
    required this.whatNeedsImprovement,
    required this.idealAnswer,
    required this.rawText,
  });

  factory InterviewFeedback.parse(String text) {
    double parsedScore = 7.0;
    final scoreMatch = RegExp(r'Score:\s*(\d+(?:\.\d+)?)\s*/\s*10', caseSensitive: false).firstMatch(text);
    if (scoreMatch != null) {
      parsedScore = (double.tryParse(scoreMatch.group(1) ?? '7') ?? 7.0).clamp(0.0, 10.0);
    }

    String extract(List<String> startKeywords, List<String> endKeywords) {
      final start = startKeywords.map(RegExp.escape).join('|');
      final end = endKeywords.map(RegExp.escape).join('|');

      final reg = RegExp(
        '(?:^|\\n)\\s*(?:\\*\\*|###?\\s*)?(?:$start)[:\\*\\s]*\\n?([\\s\\S]*?)(?=(?:\\n\\s*(?:\\*\\*|###?\\s*)?(?:$end)[:\\*\\s]*|\\Z))',
        caseSensitive: false,
      );
      final match = reg.firstMatch(text);
      return match?.group(1)?.trim() ?? '';
    }

    final correct = extract(
      ['WHAT WAS CORRECT', 'WHAT WENT WELL', 'STRENGTHS', 'CORRECT'],
      ['WHAT NEEDS IMPROVEMENT', 'NEEDS IMPROVEMENT', 'IMPROVEMENT', 'IDEAL ANSWER', 'CORRECT ANSWER', 'NEXT QUESTION'],
    );

    final needsImprovement = extract(
      ['WHAT NEEDS IMPROVEMENT', 'AREAS FOR IMPROVEMENT', 'NEEDS IMPROVEMENT', 'WHAT WAS INCORRECT', 'WEAKNESSES'],
      ['IDEAL ANSWER', 'CORRECT ANSWER', 'MODEL ANSWER', 'BETTER ANSWER', 'NEXT QUESTION'],
    );

    final ideal = extract(
      ['IDEAL ANSWER', 'CORRECT ANSWER', 'MODEL ANSWER', 'BETTER ANSWER', 'RECOMMENDED ANSWER', 'SAMPLE ANSWER'],
      ['NEXT QUESTION', 'QUESTION'],
    );

    return InterviewFeedback(
      score: parsedScore,
      whatWasCorrect: correct.isNotEmpty ? correct : 'Your answer conveyed the basic core intuition.',
      whatNeedsImprovement: needsImprovement.isNotEmpty
          ? needsImprovement
          : 'Include more production considerations, edge cases, and architectural tradeoffs.',
      idealAnswer: ideal.isNotEmpty ? ideal : text,
      rawText: text,
    );
  }
}

class InterviewRoundRecord {
  final int roundNumber;
  final String question;
  final String candidateAnswer;
  final InterviewFeedback feedback;

  InterviewRoundRecord({
    required this.roundNumber,
    required this.question,
    required this.candidateAnswer,
    required this.feedback,
  });
}

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  final TextEditingController _answerController = TextEditingController();

  static const int maxQuestions = 5;

  final List<String> jobRoles = [
    'Flutter Developer',
    'Node.js Developer',
    'Python Developer',
    'Software Engineer',
    'React Developer',
    'Full Stack Developer',
  ];

  String selectedRole = 'Flutter Developer';

  final List<Map<String, String>> previousAnswersApiPayload = [];
  final List<InterviewRoundRecord> roundRecords = [];

  String? currentQuestion;
  InterviewFeedback? currentFeedback;
  String? nextQuestionBuffer;

  int questionIndex = 0; // 1 to 5
  bool isLoading = false;
  bool interviewStarted = false;
  bool isReviewingAnswer = false; // When true, shows evaluation + ideal answer before proceeding
  bool interviewCompleted = false;
  String? errorMessage;

  double get averageScore {
    if (roundRecords.isEmpty) return 0;
    final total = roundRecords.fold<double>(0, (sum, record) => sum + record.feedback.score);
    return total / roundRecords.length;
  }

  String extractNextQuestion(String result) {
    final match = RegExp(r'NEXT QUESTION:\s*([\s\S]*)', caseSensitive: false).firstMatch(result);
    final question = match?.group(1)?.trim();
    if (question != null && question.isNotEmpty) {
      return question;
    }
    return 'Explain your experience working with async tasks and data validation.';
  }

  // Start interview (fetches question 1)
  Future<void> startInterview() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.startInterview(
        jobRole: selectedRole,
        previousAnswers: [],
      );

      if (!mounted) return;

      final data = response['data'];
      final result = data is Map
          ? data['result']?.toString() ?? 'Explain how you structure applications in $selectedRole.'
          : 'Explain how you structure applications in $selectedRole.';

      // Question 1 from AI
      final question1 = RegExp(r'(?:Question\s*1?|Next Question)[:\s]*\s*(.+)', caseSensitive: false, dotAll: true)
              .firstMatch(result)
              ?.group(1)
              ?.trim() ??
          result.trim();

      setState(() {
        interviewStarted = true;
        questionIndex = 1;
        currentQuestion = question1;
        isReviewingAnswer = false;
        interviewCompleted = false;
        _answerController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Submit answer or request answer reveal
  Future<void> submitAnswer({bool isSkipping = false}) async {
    if (isLoading || interviewCompleted || currentQuestion == null) return;

    final answer = isSkipping
        ? "I am not fully confident about this topic. Please explain the ideal answer and key concepts."
        : _answerController.text.trim();

    if (answer.isEmpty) {
      setState(() {
        errorMessage = 'Please write an answer or tap "Show Correct Answer" to learn.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final updatedPayload = List<Map<String, String>>.from(previousAnswersApiPayload);
    updatedPayload.add({
      'question': currentQuestion!,
      'answer': answer,
    });

    try {
      final response = await ApiService.startInterview(
        jobRole: selectedRole,
        previousAnswers: updatedPayload,
      );

      if (!mounted) return;

      final data = response['data'];
      final result = data is Map
          ? data['result']?.toString() ?? 'Evaluation completed.'
          : 'Evaluation completed.';

      final feedback = InterviewFeedback.parse(result);
      final isLastQuestion = questionIndex >= maxQuestions;
      final nextQ = isLastQuestion ? null : extractNextQuestion(result);

      setState(() {
        previousAnswersApiPayload.clear();
        previousAnswersApiPayload.addAll(updatedPayload);

        roundRecords.add(InterviewRoundRecord(
          roundNumber: questionIndex,
          question: currentQuestion!,
          candidateAnswer: answer,
          feedback: feedback,
        ));

        currentFeedback = feedback;
        nextQuestionBuffer = nextQ;
        isReviewingAnswer = true; // Enter review mode to study the correct answer
        _answerController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Move from evaluation/ideal answer view to next question
  void proceedToNext() {
    if (questionIndex >= maxQuestions) {
      setState(() {
        interviewCompleted = true;
        isReviewingAnswer = false;
        currentQuestion = null;
        currentFeedback = null;
      });
    } else {
      setState(() {
        questionIndex += 1;
        currentQuestion = nextQuestionBuffer ?? 'Explain how you approach error handling and testing.';
        isReviewingAnswer = false;
        currentFeedback = null;
        nextQuestionBuffer = null;
      });
    }
  }

  void resetInterview() {
    setState(() {
      previousAnswersApiPayload.clear();
      roundRecords.clear();
      currentQuestion = null;
      currentFeedback = null;
      nextQuestionBuffer = null;
      questionIndex = 0;
      interviewStarted = false;
      isReviewingAnswer = false;
      interviewCompleted = false;
      errorMessage = null;
      _answerController.clear();
    });
  }

  void copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mock Interview AI',
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
          if (interviewStarted)
            IconButton(
              onPressed: isLoading ? null : resetInterview,
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              tooltip: 'Start Over',
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
                _buildHeaderBanner(isDark),
                const SizedBox(height: 24),

                if (!interviewStarted) ...[
                  _buildSetupCard(isDark),
                ] else if (interviewCompleted) ...[
                  _buildCompletionScreen(isDark),
                ] else if (isReviewingAnswer && currentFeedback != null) ...[
                  _buildAnswerEvaluationAndIdealAnswerView(isDark),
                ] else ...[
                  _buildActiveQuestionView(isDark),
                ],

                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
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
                            errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.amberAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Interactive Technical Interview Simulator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Answer Questions & Learn Ideal Answers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Simulate a 5-round technical screening. Get scored, pinpoint improvements, and review interview-ready correct answers for every question.',
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

  Widget _buildSetupCard(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Target Engineering Role',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
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
            items: jobRoles.map((role) {
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
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedRole = value);
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 18),
              const SizedBox(width: 8),
              Text(
                '5 progressive technical questions tailored to your role',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 18),
              const SizedBox(width: 8),
              Text(
                'Instant score (out of 10) + detailed correct answers',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            onPressed: isLoading ? null : startInterview,
            text: 'Begin Mock Interview Session',
            icon: Icons.play_arrow_rounded,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  // Active question input view
  Widget _buildActiveQuestionView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper progress
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Round $questionIndex of $maxQuestions • $selectedRole',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  StatusBadge.primary(
                    label: 'Question $questionIndex',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: questionIndex / maxQuestions,
                  minHeight: 8,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // AI Question Card
        AppCard(
          padding: const EdgeInsets.all(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Interviewer Question',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SelectableText(
                currentQuestion ?? 'Loading question...',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Candidate Answer Box
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Answer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Explain the core concept clearly with examples or architectural considerations:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerController,
                maxLines: 7,
                enabled: !isLoading,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your technical answer here in detail...',
                  fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GradientButton(
                      onPressed: isLoading ? null : () => submitAnswer(isSkipping: false),
                      text: isLoading ? 'Evaluating Answer...' : 'Submit Answer',
                      icon: Icons.send_rounded,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : () => submitAnswer(isSkipping: true),
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      label: const Text('Show Answer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Round evaluation + IDEAL / CORRECT ANSWER REVEAL VIEW
  Widget _buildAnswerEvaluationAndIdealAnswerView(bool isDark) {
    final feedback = currentFeedback!;
    final score = feedback.score;
    final isGoodScore = score >= 8.0;
    final isAverageScore = score >= 5.0 && score < 8.0;

    final Color scoreColor = isGoodScore
        ? AppColors.accentEmerald
        : (isAverageScore ? AppColors.accentAmber : AppColors.error);

    final Color scoreBg = isGoodScore
        ? (isDark ? AppColors.accentEmeraldSoftDark : AppColors.accentEmeraldSoft)
        : (isAverageScore
            ? (isDark ? AppColors.accentAmberSoftDark : AppColors.accentAmberSoft)
            : (isDark ? AppColors.accentRoseSoftDark : AppColors.accentRoseSoft));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score Header Card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: scoreBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Round $questionIndex Evaluation',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: '$score / 10',
                          backgroundColor: scoreBg,
                          textColor: scoreColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGoodScore
                          ? 'Impressive response! Strong conceptual clarity.'
                          : (isAverageScore
                              ? 'Good foundation. Review the model answer below to sharpen accuracy.'
                              : 'Review the correct answer below to master this concept for interviews.'),
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
        ),
        const SizedBox(height: 18),

        // What was correct
        if (feedback.whatWasCorrect.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: isDark ? AppColors.accentEmeraldSoftDark : const Color(0xFFF0FDF4),
            border: Border.all(color: AppColors.accentEmerald.withValues(alpha: isDark ? 0.35 : 0.25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'What Was Correct in Your Response',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.accentEmerald : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  feedback.whatWasCorrect,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF14532D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // What needs improvement
        if (feedback.whatNeedsImprovement.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: isDark ? AppColors.accentAmberSoftDark : const Color(0xFFFFFBEB),
            border: Border.all(color: AppColors.accentAmber.withValues(alpha: isDark ? 0.35 : 0.3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppColors.accentAmber, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Areas for Improvement / Missing Points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.accentAmber : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  feedback.whatNeedsImprovement,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // THE HERO: CORRECT / IDEAL ANSWER CARD
        AppCard(
          padding: const EdgeInsets.all(22),
          border: Border.all(color: AppColors.primary, width: 1.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ideal / Correct Answer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Recommended technical phrasing for hiring managers',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => copyToClipboard(feedback.idealAnswer, 'Ideal Answer'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: SelectableText(
                  feedback.idealAnswer,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Proceed CTA Button
        GradientButton(
          onPressed: proceedToNext,
          text: questionIndex >= maxQuestions
              ? 'Complete Interview & View Report →'
              : 'Proceed to Question ${questionIndex + 1} of $maxQuestions →',
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  // Interview completion report with ALL questions + ALL correct answers
  Widget _buildCompletionScreen(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trophy Hero Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.accentEmeraldSoftDark : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accentEmerald.withValues(alpha: isDark ? 0.35 : 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.accentEmerald,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Interview Completed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You completed all $maxQuestions technical rounds for $selectedRole.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 18),

              // Metrics row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatTile('Average Score', '${averageScore.toStringAsFixed(1)} / 10', isDark),
                  _buildStatTile('Rounds Answered', '${roundRecords.length} / $maxQuestions', isDark),
                  _buildStatTile('Rating', averageScore >= 8 ? 'Strong Hire' : (averageScore >= 6 ? 'Hire' : 'Needs Prep'), isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const SectionHeader(
          title: 'Full Interview Review & Model Answers',
          subtitle: 'Review your responses alongside the ideal answers for each question',
        ),
        const SizedBox(height: 14),

        // Accordion for all 5 questions
        ...roundRecords.map((record) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: record.roundNumber == 1,
                tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                title: Text(
                  'Q${record.roundNumber}: ${record.question}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                trailing: StatusBadge(
                  label: '${record.feedback.score} / 10',
                  backgroundColor: record.feedback.score >= 8
                      ? (isDark ? AppColors.accentEmeraldSoftDark : AppColors.accentEmeraldSoft)
                      : (record.feedback.score >= 5
                          ? (isDark ? AppColors.accentAmberSoftDark : AppColors.accentAmberSoft)
                          : (isDark ? AppColors.accentRoseSoftDark : AppColors.accentRoseSoft)),
                  textColor: record.feedback.score >= 8
                      ? AppColors.accentEmerald
                      : (record.feedback.score >= 5 ? AppColors.accentAmber : AppColors.error),
                ),
                children: [
                  // Candidate answer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          record.candidateAnswer,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ideal Answer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Correct / Ideal Answer:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                              onPressed: () => copyToClipboard(record.feedback.idealAnswer, 'Ideal Answer'),
                              tooltip: 'Copy Ideal Answer',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          record.feedback.idealAnswer,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 20),
        GradientButton(
          onPressed: resetInterview,
          text: 'Start Another Practice Interview',
          icon: Icons.refresh_rounded,
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.accentEmerald : const Color(0xFF14532D),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF166534),
          ),
        ),
      ],
    );
  }
}
