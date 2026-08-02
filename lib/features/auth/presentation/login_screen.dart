import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

import '../../../app/theme/colors.dart';

/// Giriş ekranı — e-posta + tek kullanımlık kod (OTP) akışının arayüzü.
///
/// Faz 0'da yalnızca arayüz vardır; Supabase Auth bağlantısı Faz 1'de
/// bu ekrana eklenecek. Saha ergonomisi: tek elle erişilebilir tek buton,
/// büyük giriş alanı, minimum yazı girişi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendCode() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    // Faz 1: Supabase signInWithOtp çağrısı buraya bağlanacak.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loginComingSoon)),
    );
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : l10n.emailInvalid;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 40),
                    Text(
                      l10n.loginWelcome,
                      style: textTheme.headlineLarge
                          ?.copyWith(color: BaibarsColors.deepGreen),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.loginSubtitle, style: textTheme.bodyLarge),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        hintText: l10n.emailHint,
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (v) => _validateEmail(v, l10n),
                      onFieldSubmitted: (_) => _onSendCode(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _onSendCode,
                      child: Text(l10n.sendCodeButton),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      l10n.brandTagline,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: BaibarsColors.deepGreen),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marka işareti — uygulama ikonu hazır olana kadar tipografik yer tutucu.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: BaibarsColors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text(
            'b',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.appTitle,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: BaibarsColors.blue),
        ),
      ],
    );
  }
}
