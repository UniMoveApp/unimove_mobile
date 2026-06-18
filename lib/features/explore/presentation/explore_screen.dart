import 'package:flutter/material.dart';
import '../../../shared/widgets/wip_placeholder.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WipPlaceholder(
      title: 'Esplora',
      subtitle: 'Work in progress - disponibile nella prossima versione',
      icon: Icons.map_outlined,
    );
  }
}
