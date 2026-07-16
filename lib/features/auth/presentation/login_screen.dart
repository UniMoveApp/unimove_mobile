import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TermsAndConditionsSheet(
        onAccept: () {
          setState(() => _acceptTerms = true);
          Navigator.pop(context);
        },
        onDecline: () {
          setState(() => _acceptTerms = false);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Accetta i termini e le condizioni per continuare',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!success && mounted) {
      final error = ref.read(authControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Credenziali non valide',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Calculate responsive sizes
    final double logoContainerSize = (screenHeight * 0.22).clamp(120.0, 180.0);
    final double logoImageSize = logoContainerSize * 0.6;
    final double verticalPadding = (screenHeight * 0.05).clamp(20.0, 40.0);
    final double topSpacing = (screenHeight * 0.04).clamp(10.0, 40.0);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: verticalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (verticalPadding * 2),
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topSpacing),
                        // Logo UniMove - Enlarged Circle (Responsive)
                        Center(
                          child: Container(
                            width: logoContainerSize,
                            height: logoContainerSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: logoImageSize,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    'UM',
                                    style: TextStyle(
                                      color: AppColors.charcoal,
                                      fontSize: logoContainerSize * 0.3,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'UniMove',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Accedi per iniziare il tuo viaggio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(), // Pushes the form down if there's space
                        const SizedBox(height: 32),

                        _buildLabel('Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: 'n.cognome'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci lo username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Checkbox e Link Termini
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _acceptTerms,
                                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                activeColor: AppColors.universityGreen,
                                checkColor: Colors.white,
                                side: const BorderSide(color: AppColors.textMuted, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showTermsAndConditions,
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Accetto ',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: 'Condizioni d\'Uso e Privacy',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: AppColors.universityGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(), // Pushes everything apart
                        const SizedBox(height: 32),

                        if (authState.errorMessage != null) ...[
                          Text(
                            authState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Bottone Accedi
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Accedi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}

class TermsAndConditionsSheet extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TermsAndConditionsSheet({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Condizioni d\'uso e Privacy',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy dei dati',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'I tuoi dati personali saranno trattati esclusivamente per le finalità legate all\'erogazione del servizio di carpooling UniMove. Garantiamo la massima riservatezza e il rispetto delle normative vigenti sul trattamento dei dati (GDPR). Le informazioni sul tuo profilo e sui viaggi saranno visibili solo agli utenti registrati della community.',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Condizioni d\'uso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Utilizzando UniMove, accetti di condividere i passaggi in modo responsabile e sicuro. Ti impegni a rispettare gli orari e gli accordi presi con gli altri utenti. UniMove è una piattaforma dedicata agli studenti e al personale universitario per facilitare la mobilità sostenibile. Qualsiasi abuso della piattaforma potrà portare alla sospensione dell\'account.',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onAccept,
            child: const Text('Accetta e continua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onDecline,
            child: const Text('Rifiuta', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}