import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            _buildSettingsItem(
              icon: Icons.person_outline,
              label: 'Preferenze profilo',
              onTap: () {
                context.push('/profilo/edit-preferences');
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.account_balance_outlined,
              label: 'Informazioni bancarie',
              onTap: () {
                context.push('/profilo/edit-iban');
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.alt_route_outlined,
              label: 'Preferenze tratte',
              onTap: () {
                context.push('/profilo/edit-routes');
              },
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: Icons.logout,
              label: 'Logout',
              labelColor: const Color(0xFFE57373),
              iconColor: const Color(0xFFE57373),
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.cardDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text(
                    'Conferma logout',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'Sei sicuro di voler uscire?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authControllerProvider.notifier).logout();
                      },
                      child: const Text(
                        'Esci',
                        style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 16,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
    bool isLast = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white.withValues(alpha: 0.7)),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: isLast
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            )
          : null,
    );
  }
}
