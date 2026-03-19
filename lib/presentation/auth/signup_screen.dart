import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/storage/character_storage.dart';
import '../../domain/repositories/profile_repository.dart';
import '../locale/l10n_context.dart';
import '../locale/locale_notifier.dart';
import 'auth_error_mapper.dart' show formatSignUpError;
import 'auth_state.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _statusMessageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;
  XFile? _pickedAvatar;

  @override
  void dispose() {
    _displayNameController.dispose();
    _statusMessageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _pickedAvatar = x);
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
      final profileRepo = context.read<ProfileRepository>();
      final response = await context.read<AppAuthState>().signUp(
            _emailController.text.trim(),
            _passwordController.text,
            displayName: _displayNameController.text.trim(),
            statusMessage: _statusMessageController.text.trim().isEmpty
                ? null
                : _statusMessageController.text.trim(),
          );
      if (!mounted) return;

      final user = response.user;
      final session = response.session;
      if (user != null && session != null && _pickedAvatar != null) {
        try {
          final url = await CharacterStorage.uploadAvatar(user.id, File(_pickedAvatar!.path));
          final profile = await profileRepo.getProfile(user.id);
          if (profile != null && mounted) {
            await profileRepo.updateProfile(profile.copyWith(avatarUrl: url));
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('signUpAvatarUploadFailed'))),
            );
          }
        }
      } else if (user != null && session == null && _pickedAvatar != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('signUpAvatarAfterLogin'))),
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      final msg = session != null ? context.tr('signUpDoneLoggedIn') : context.tr('signUpDoneConfirmEmail');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      context.read<AppAuthState>().toggleSignUp();
    } catch (e) {
      if (!mounted) return;
      final code = context.read<LocaleNotifier>().languageCode;
      setState(() {
        _error = formatSignUpError(e, code);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  context.tr('signUpTitle'),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _displayNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.tr('displayNameLabel'),
                    hintText: context.tr('displayNameHint'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return context.tr('displayNameRequired');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _statusMessageController,
                  decoration: InputDecoration(
                    labelText: context.tr('profileStatusMessageLabel'),
                    hintText: context.tr('profileStatusMessageHint'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Text(context.tr('signUpProfilePhoto'), style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: Text(context.tr('pickFromGallery')),
                    ),
                    const SizedBox(width: 12),
                    if (_pickedAvatar != null)
                      Expanded(
                        child: Text(
                          _pickedAvatar!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.tr('emailLabel'),
                    hintText: 'example@email.com',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return context.tr('emailRequired');
                    if (!v.contains('@')) return context.tr('emailInvalid');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: context.tr('passwordLabel'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return context.tr('passwordMinLength');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: context.tr('passwordConfirmLabel'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return context.tr('passwordMismatch');
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('signUp')),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.read<AppAuthState>().toggleSignUp(),
                  child: Text(context.tr('loginLink')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
