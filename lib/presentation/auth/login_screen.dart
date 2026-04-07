import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'auth_error_mapper.dart' show formatLoginError;
import 'auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      await context.read<AppAuthState>().signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (!mounted) return;
      final code = context.read<LocaleNotifier>().languageCode;
      setState(() {
        _error = formatLoginError(e, code);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라디언트
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.45),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          // 배경 데코 원
          Positioned(
            top: -60,
            right: -50,
            child: _DecoCircle(size: 220, color: scheme.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: _DecoCircle(size: 180, color: scheme.tertiary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: _DecoCircle(size: 140, color: scheme.secondary.withValues(alpha: 0.07)),
          ),
          // 콘텐츠
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 52),
                    // 로고 영역
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [scheme.primary, scheme.tertiary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌸', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Avoid TextStyle.foreground + Paint.createShader on title: has caused
                    // EXC_BAD_ACCESS on some iOS/Skia device builds; ShaderMask is a safer gradient path.
                    Center(
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) {
                          final w = bounds.width <= 0 ? 1.0 : bounds.width;
                          final h = bounds.height <= 0 ? 1.0 : bounds.height;
                          return LinearGradient(
                            colors: [scheme.primary, scheme.tertiary],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(Rect.fromLTWH(0, 0, w, h));
                        },
                        child: Text(
                          'トモトモ',
                          style: AppTextStyles.pageTitle(context).copyWith(
                            fontSize: 30,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('loginTagline'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // 폼 카드
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: context.tr('emailLabel'),
                              hintText: 'example@email.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded, color: scheme.primary),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return context.tr('emailRequired');
                              if (!v.contains('@')) return context.tr('emailInvalid');
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: context.tr('passwordLabel'),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: scheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return context.tr('passwordRequired');
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Text(context.tr('login')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<AppAuthState>().toggleSignUp(),
                      child: Text(context.tr('signUpLink')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
