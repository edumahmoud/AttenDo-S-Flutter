import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../i18n/app_localizations.dart';
import '../../services/auth_service.dart' hide authStateProvider;
import '../../config/routes/route_guards.dart' show appAuthStateProvider, AppAuthState;

/// Full-featured login screen matching the original AttenDo design.
///
/// Features:
/// - App logo and name at top
/// - Email input field
/// - Password input field with show/hide toggle
/// - "Forgot password?" link
/// - Login button with loading state
/// - "Sign in with Google" button
/// - "Don't have an account? Register" link
/// - Error message display
/// - RTL support
/// - Ocean blue gradient background
/// - Responsive layout (centered card on larger screens)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profile = await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profile = await authService.signInWithGoogle();

      if (!mounted) return;

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
                      // ─── Logo and Name ───
                      _buildLogoSection(context, brightness, loc),

                      const SizedBox(height: 32),

                      // ─── Login Card ───
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
                                // Welcome text
                                Text(
                                  loc.t('auth.login.welcome'),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.t('auth.login.subtitle'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 24),

                                // ─── Error message ───
                                if (_errorMessage != null)
                                  _buildErrorMessage(context),

                                // ─── Email ───
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: loc.t('auth.login.emailLabel'),
                                    hintText:
                                        loc.t('auth.login.emailPlaceholder'),
                                    prefixIcon: const Icon(
                                        Icons.email_outlined, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return loc.t(
                                          'auth.login.errorEmailRequired');
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ─── Password ───
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    labelText:
                                        loc.t('auth.login.passwordLabel'),
                                    hintText:
                                        loc.t('auth.login.passwordPlaceholder'),
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
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      tooltip: _obscurePassword
                                          ? loc.t('auth.login.showPassword')
                                          : loc.t('auth.login.hidePassword'),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return loc.t(
                                          'auth.login.errorPasswordRequired');
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 8),

                                // ─── Forgot Password ───
                                Align(
                                  alignment: loc.isRTL
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      context.go('/forgot-password');
                                    },
                                    child: Text(
                                      loc.t('auth.login.forgotPassword'),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ─── Login Button ───
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _handleLogin,
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
                                            loc.t('auth.login.submit'),
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
                                        loc.t('auth.login.or'),
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

                                // ─── Google Sign-In ───
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleGoogleSignIn,
                                    icon: const Icon(
                                      Icons.g_mobiledata_rounded,
                                      size: 24,
                                    ),
                                    label: Text(
                                      loc.t('auth.login.googleSignIn'),
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

                      // ─── Register Link ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.t('auth.login.noAccount'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: brightness == Brightness.light
                                  ? Colors.white70
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: Text(
                              loc.t('auth.login.createAccount'),
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

  Widget _buildLogoSection(
    BuildContext context,
    Brightness brightness,
    AppLocalizations loc,
  ) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          loc.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.appTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
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
