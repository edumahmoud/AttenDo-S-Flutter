import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/constants/app_constants.dart';
import '../../i18n/app_localizations.dart';
import '../../services/auth_service.dart' hide authStateProvider;
import '../../config/routes/route_guards.dart' show appAuthStateProvider, AppAuthState;

/// Full-featured registration screen.
///
/// Features:
/// - Name, email, password, confirm password fields
/// - Password strength indicator
/// - Terms acceptance checkbox
/// - Register button with loading state
/// - "Already have an account? Login" link
/// - Error message display
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Calculate password strength 0-4.
  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      strength++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
    }
    return strength.clamp(0, 4);
  }

  String _getStrengthLabel(int strength, AppLocalizations loc) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return loc.t('auth.register.passwordStrengthWeak');
      case 2:
        return loc.t('auth.register.passwordStrengthMedium');
      case 3:
        return loc.t('auth.register.passwordStrengthGood');
      case 4:
        return loc.t('auth.register.passwordStrengthStrong');
      default:
        return '';
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return AppColors.lightTealAccent;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'يجب الموافقة على الشروط والأحكام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profile = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      // Update auth state
      ref.read(appAuthStateProvider.notifier).state = AppAuthState(
        isAuthenticated: true,
        userRole: profile.role,
        userId: profile.id,
      );

      context.go('/student/dashboard');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final size = MediaQuery.sizeOf(context);
    final isWideScreen = size.width > 600;

    final passwordStrength = _getPasswordStrength(_passwordController.text);

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.ocean(brightness),
                AppColors.ocean(brightness).withValues(alpha: 0.8),
                brightness == Brightness.light
                    ? const Color(0xFFE0F2FE)
                    : AppColors.darkScaffoldBackground,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 440 : 380,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── Logo ───
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.t('auth.register.title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.t('auth.register.subtitle',
                            args: {'displayName': loc.appName}),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // ─── Register Card ───
                      Card(
                        elevation: isWideScreen ? 8 : 4,
                        shadowColor: Colors.black.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ─── Error message ───
                                if (_errorMessage != null)
                                  _buildErrorMessage(context),

                                // ─── Full Name ───
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText:
                                        loc.t('auth.register.fullNameLabel'),
                                    hintText: loc
                                        .t('auth.register.fullNamePlaceholder'),
                                    prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return loc.t(
                                          'auth.register.errorNameRequired');
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ─── Email ───
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText:
                                        loc.t('auth.register.emailLabel'),
                                    hintText:
                                        loc.t('auth.register.emailPlaceholder'),
                                    prefixIcon: const Icon(
                                        Icons.email_outlined, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return loc.t(
                                          'auth.register.errorEmailRequired');
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ─── Password ───
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText:
                                        loc.t('auth.register.passwordLabel'),
                                    hintText: loc
                                        .t('auth.register.passwordPlaceholder'),
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return loc.t(
                                          'auth.register.errorPasswordRequired');
                                    }
                                    if (value.length <
                                        AppConstants.passwordMinLength) {
                                      return loc.t(
                                          'auth.register.errorPasswordMinLength');
                                    }
                                    return null;
                                  },
                                ),

                                // ─── Password Strength Indicator ───
                                if (_passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        loc.t(
                                            'auth.register.passwordStrength'),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ...List.generate(4, (index) {
                                        return Expanded(
                                          child: Container(
                                            height: 4,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              color: index < passwordStrength
                                                  ? _getStrengthColor(
                                                      passwordStrength)
                                                  : theme.colorScheme.outline
                                                      .withValues(alpha: 0.3),
                                            ),
                                          ),
                                        );
                                      }),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getStrengthLabel(
                                            passwordStrength, loc),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: _getStrengthColor(
                                              passwordStrength),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // ─── Confirm Password ───
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleRegister(),
                                  decoration: InputDecoration(
                                    labelText: loc.t(
                                        'auth.register.confirmPasswordLabel'),
                                    hintText: loc.t(
                                        'auth.register.confirmPasswordPlaceholder'),
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return loc.t(
                                          'auth.register.errorPasswordRequired');
                                    }
                                    if (value !=
                                        _passwordController.text) {
                                      return loc.t(
                                          'auth.register.errorPasswordMismatch');
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // ─── Terms checkbox ───
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _acceptTerms = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        loc.t(
                                            'auth.register.studentDefaultNote'),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ─── Register Button ───
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.ocean(brightness),
                                      foregroundColor: AppColors.oceanForeground(
                                          brightness),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.oceanForeground(
                                                  brightness),
                                            ),
                                          )
                                        : Text(
                                            loc.t('auth.register.submit'),
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              color: AppColors.oceanForeground(
                                                  brightness),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ─── Divider ───
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        loc.t('auth.register.or'),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ─── Google Sign-Up ───
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            // TODO: Google sign up
                                          },
                                    icon: const Icon(
                                      Icons.g_mobiledata_rounded,
                                      size: 24,
                                    ),
                                    label: Text(
                                      loc.t('auth.register.googleSignUp'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── Login Link ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.t('auth.register.hasAccount'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: brightness == Brightness.light
                                  ? Colors.white70
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              loc.t('auth.register.signIn'),
                              style: TextStyle(
                                color: brightness == Brightness.light
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: theme.colorScheme.onErrorContainer,
            ),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
