import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/custom_widgets.dart';
import 'dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.accentEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // STEP 1: Validate input and send OTP to real email
  Future<void> _handleInitiateSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all required fields', isError: true);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Please enter a valid email address', isError: true);
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters long', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.sendOtp(
        email: email,
        type: 'signup',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isOtpSent = true;
          if (result['devOtp'] != null) {
            _otpController.text = result['devOtp'].toString();
          } else {
            _otpController.clear();
          }
        });
        _startResendTimer();
        _showMessage(result['message'] ?? 'Verification code sent to your email! Please check your inbox.');
      } else {
        _showMessage(result['message'] ?? 'Failed to send verification code. Try again.', isError: true);
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // STEP 2: Verify OTP and create user account
  Future<void> _handleVerifyAndCompleteSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit verification code', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.verifyOtp(
        email: email,
        otp: otp,
        name: name,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true && result['token'] != null) {
        final token = result['token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        if (!mounted) return;

        _showMessage('Account verified and created successfully! Welcome.');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(token: token),
          ),
        );
      } else {
        _showMessage(result['message'] ?? 'Invalid or expired OTP code', isError: true);
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.background,
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF141417),
                    Color(0xFF09090B),
                    Color(0xFF050507),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF9FAFB),
                    Color(0xFFF3F4F6),
                    Color(0xFFECFDF5),
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back and Theme Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.subtle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        tooltip: 'Back',
                        onPressed: () {
                          if (_isOtpSent) {
                            setState(() => _isOtpSent = false);
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.subtle,
                      ),
                      child: IconButton(
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 20,
                          color: isDark ? Colors.amberAccent : AppColors.textSecondary,
                        ),
                        onPressed: () => themeController.toggleTheme(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Signup Form
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Signup Card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.border,
                                width: 1.2,
                              ),
                              boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
                            ),
                            child: _isOtpSent
                                ? _buildOtpVerificationView(isDark)
                                : _buildSignupFormView(isDark),
                          ),

                          const SizedBox(height: 22),

                          // Back to Login Prompt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 1 VIEW: Full Name, Email, Password
  Widget _buildSignupFormView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
                ),
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Started Free',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlock your AI career workspace today',
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

        // Full name label
        Text(
          'Full Name',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Your Full Name',
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          ),
        ),
        const SizedBox(height: 18),

        // Email label
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'youremail@example.com',
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          ),
        ),
        const SizedBox(height: 18),

        // Password label
        Text(
          'Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleInitiateSignup(),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Signup button
        GradientButton(
          onPressed: _isLoading ? null : _handleInitiateSignup,
          text: 'Send Verification Code',
          icon: Icons.arrow_forward_rounded,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // STEP 2 VIEW: Enter 6-digit verification code
  Widget _buildOtpVerificationView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.accentEmeraldSoftDark : AppColors.accentEmeraldSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentEmerald.withValues(alpha: isDark ? 0.35 : 0.25),
                ),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.accentEmerald,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Code sent to ${_emailController.text}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Email changer chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.mail_outline_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _emailController.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _isOtpSent = false);
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        Text(
          'Enter 6-Digit Code',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(
              fontSize: 24,
              letterSpacing: 10,
              color: (isDark ? AppColors.darkTextMuted : AppColors.textMuted).withValues(alpha: 0.5),
            ),
            fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
            prefixIcon: const Icon(
              Icons.lock_clock_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          onSubmitted: (_) => _handleVerifyAndCompleteSignup(),
        ),
        const SizedBox(height: 20),

        // Resend Timer & Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _resendCountdown > 0
                  ? 'Resend available in ${_resendCountdown}s'
                  : 'Didn\'t receive code?',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: (_resendCountdown > 0 || _isLoading)
                  ? null
                  : _handleInitiateSignup,
              child: Text(
                'Resend Code',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _resendCountdown > 0
                      ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        GradientButton(
          onPressed: _isLoading ? null : _handleVerifyAndCompleteSignup,
          text: 'Confirm & Create Account',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
