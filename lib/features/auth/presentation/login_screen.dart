import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    print("[DEBUG UI] Bottone Accedi cliccato.");
    if (!_formKey.currentState!.validate()) {
      print("[DEBUG UI] Validazione del form fallita.");
      return;
    }

    if (!_acceptTerms) {
      print("[DEBUG UI] Termini non accettati. Blocco l'operazione.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accetta i termini e le condizioni per continuare'),
          backgroundColor: Color(0xFF323232),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    print("[DEBUG UI] Avvio chiamata di login tramite AuthController...");
    final success = await ref.read(authControllerProvider.notifier).login(
      _usernameController.text,
      _passwordController.text,
    );

    print("[DEBUG UI] Esito del login: $success");
    if (!success && mounted) {
      final error = ref.read(authControllerProvider).errorMessage;
      print("[DEBUG UI] Errore mostrato in SnackBar: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Credenziali non valide'),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Logo UniMove
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFF673AB7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'UM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Bentornato su UniMove',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accedi per iniziare il tuo viaggio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                _buildLabel('Username'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration(hintText: 'n.cognome'),
                ),
                const SizedBox(height: 20),

                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Checkbox e Link Termini
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                        activeColor: Colors.black,
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
                            style: TextStyle(color: Colors.black54, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Condizioni d\'Uso e Privacy',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.black,
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
                const SizedBox(height: 40),

                // Bottone Accedi
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Accedi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  InputDecoration _inputDecoration({required String hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12, width: 2),
      ),
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
        color: Colors.white,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Condizioni d\'uso e Privacy',
            style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy dei dati',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'I tuoi dati personali saranno trattati esclusivamente per le finalità legate all\'erogazione del servizio di carpooling UniMove. Garantiamo la massima riservatezza e il rispetto delle normative vigenti sul trattamento dei dati (GDPR). Le informazioni sul tuo profilo e sui viaggi saranno visibili solo agli utenti registrati della community.',
                    style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Condizioni d\'uso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Utilizzando UniMove, accetti di condividere i passaggi in modo responsabile e sicuro. Ti impegni a rispettare gli orari e gli accordi presi con gli altri utenti. UniMove è una piattaforma dedicata agli studenti e al personale universitario per facilitare la mobilità sostenibile. Qualsiasi abuso della piattaforma potrà portare alla sospensione dell\'account.',
                    style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Accetta e continua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onDecline,
            child: const Text('Rifiuta', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
