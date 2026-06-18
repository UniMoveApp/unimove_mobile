import 'package:flutter/material.dart';
import '../../../shared/widgets/wip_placeholder.dart';

class SearchRideScreen extends StatelessWidget {
  const SearchRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WipPlaceholder(
      title: 'Cerca Corsa',
      subtitle: 'Work in progress - disponibile nella prossima versione',
      icon: Icons.search,
    );
  }
}
