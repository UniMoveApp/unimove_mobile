import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WipPlaceholder extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;

  const WipPlaceholder({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.universityGreen.withValues(alpha: 0.1),
                  width: 4,
                ),
              ),
              child: Icon(
                icon ?? Icons.construction_outlined,
                size: 64,
                color: AppColors.universityGreen,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title ?? 'Work in Progress',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle ?? 'Disponibile nella prossima versione',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.universityGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.universityGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Stay tuned!',
                    style: TextStyle(
                      color: AppColors.universityGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
