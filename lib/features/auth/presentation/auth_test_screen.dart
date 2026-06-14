import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import 'auth_controller.dart';

class AuthTestScreen extends ConsumerStatefulWidget {
  const AuthTestScreen({super.key});

  @override
  ConsumerState<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends ConsumerState<AuthTestScreen> {
  String? _rawToken;
  Map<String, dynamic>? _decodedPayload;
  bool _isLoadingProfile = false;
  String? _apiResult;
  bool _isSuccessApi = false;

  @override
  void initState() {
    super.initState();
    _loadTokenDetails();
  }

  Future<void> _loadTokenDetails() async {
    final token = await ref.read(authServiceProvider).getToken();
    if (token != null) {
      try {
        final jwt = JWT.decode(token);
        setState(() {
          _rawToken = token;
          _decodedPayload = jwt.payload;
        });
      } catch (e) {
        setState(() {
          _rawToken = token;
          _decodedPayload = {'error': 'Impossibile decodificare il token: $e'};
        });
      }
    }
  }

  Future<void> _testProfileApi() async {
    setState(() {
      _isLoadingProfile = true;
      _apiResult = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('users/me');
      
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _apiResult = encoder.convert(response.data);
        _isSuccessApi = true;
        _isLoadingProfile = false;
      });
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData != null 
          ? const JsonEncoder.withIndent('  ').convert(errorData) 
          : e.toString();
      setState(() {
        _apiResult = "Errore della chiamata:\n$errorMessage";
        _isSuccessApi = false;
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _apiResult = "Errore imprevisto:\n$e";
        _isSuccessApi = false;
        _isLoadingProfile = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token copiato negli appunti!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch to react to global auth changes
    ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Auth Test Control Center', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTokenDetails,
            tooltip: 'Ricarica Token',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stato Autenticazione (Card principale)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF673AB7), Color(0xFFE91E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stato Sessione',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51), // approx 0.2 opacity
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Autenticato',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _decodedPayload?['fullName'] ?? _decodedPayload?['sub'] ?? 'Utente Connesso',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Username: ${_decodedPayload?['sub'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14),
                    ),
                    if (_decodedPayload?['role'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ruolo: ${_decodedPayload?['role']}',
                        style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Ispezione Token JWT
              _buildSectionTitle('JWT Token Info'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withAlpha(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Token Raw', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _rawToken ?? 'Nessun token presente',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                          if (_rawToken != null)
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                              onPressed: () => _copyToClipboard(_rawToken!),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Payload Decodificato', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _decodedPayload != null 
                            ? const JsonEncoder.withIndent('  ').convert(_decodedPayload) 
                            : 'Nessun payload',
                        style: const TextStyle(color: Colors.tealAccent, fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Test API Protetta
              _buildSectionTitle('Test API Protetta (/api/users/me)'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withAlpha(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Invia una richiesta GET autenticata al backend per verificare il funzionamento del token.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoadingProfile ? null : _testProfileApi,
                      icon: _isLoadingProfile 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.network_ping),
                      label: const Text('Esegui Chiamata /users/me'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF121212),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.withAlpha(51)),
                        ),
                      ),
                    ),
                    if (_apiResult != null) ...[
                      const SizedBox(height: 16),
                      const Text('Risposta API', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSuccessApi ? Colors.green.withAlpha(127) : Colors.red.withAlpha(127)
                          ),
                        ),
                        child: Text(
                          _apiResult!,
                          style: TextStyle(
                            color: _isSuccessApi ? Colors.greenAccent : Colors.redAccent, 
                            fontFamily: 'monospace', 
                            fontSize: 12
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bottone Logout
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Disconnetti (Logout)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
