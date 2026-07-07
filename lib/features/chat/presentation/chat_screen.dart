import 'package:flutter/material.dart';
import '../../../shared/widgets/wip_placeholder.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WipPlaceholder(
      title: 'Chat',
      subtitle: 'Work in progress - disponibile nella prossima versione',
      icon: Icons.chat_bubble_outline,
    );
  }
}
