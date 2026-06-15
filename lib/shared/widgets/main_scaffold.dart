import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_filled, '/home'),
            _buildNavItem(context, Icons.map_outlined, '/esplora'),
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
    const accentColor = Color(0xFFE91E63);

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
                color: Colors.black,
                shape: BoxShape.circle,
              )
            : isActive
                ? BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
        child: Icon(
          icon,
          color: isCenter ? Colors.white : (isActive ? accentColor : Colors.black54),
          size: isCenter ? 30 : 26,
        ),
      ),
    );
  }
}
