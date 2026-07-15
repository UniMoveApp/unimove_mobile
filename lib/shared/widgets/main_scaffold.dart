import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final String currentRoute;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAppBar = currentRoute != '/corse/cerca' && currentRoute != '/chat';
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.deepBlack,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => context.go('/impostazioni'),
              ),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                  onPressed: () => context.push('/notifiche'),
                ),
              ],
            )
          : null,
      body: body,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_filled, '/home'),
            _buildNavItem(context, Icons.chat_bubble_outline, '/chat'),
            _buildNavItem(context, Icons.add, '/corse/crea', isCenter: true),
            _buildNavItem(context, Icons.search, '/corse/cerca'),
            _buildNavItem(context, Icons.person_outline, '/profilo'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String route, {bool isCenter = false}) {
    bool isActive = currentRoute == route;
    const accentColor = AppColors.universityGreen;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isCenter
            ? const BoxDecoration(
                color: AppColors.universityGreen,
                shape: BoxShape.circle,
              )
            : isActive
                ? BoxDecoration(
                    color: AppColors.universityGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  )
                : const BoxDecoration(
                    color: Colors.transparent,
                  ),
        child: Icon(
          icon,
          color: isCenter ? Colors.white : (isActive ? accentColor : AppColors.textMuted),
          size: isCenter ? 30 : 26,
        ),
      ),
    );
  }
}