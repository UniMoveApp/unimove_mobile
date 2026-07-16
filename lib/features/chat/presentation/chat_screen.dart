import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_controller.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../shared/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  Ride? _selectedRide;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _shareLocation() async {
    if (_selectedRide == null) return;
    try {
      // Simulate passenger sharing GPS location at UniMol Campobasso campus
      const double mockLat = 41.5605;
      const double mockLng = 14.6595;

      await ref.read(chatServiceProvider).sendMessage(
            _selectedRide!.id,
            '📍 Posizione di ritrovo condivisa',
            latitude: mockLat,
            longitude: mockLng,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione condivisa con successo!'),
          backgroundColor: AppColors.universityGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedRide == null) return;

    _messageController.clear();

    try {
      await ref.read(chatServiceProvider).sendMessage(_selectedRide!.id, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRide != null) {
      return _buildChatDetail(_selectedRide!);
    }
    return _buildChatList();
  }

  Widget _buildChatList() {
    final activeChatsAsync = ref.watch(activeChatsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => context.go('/impostazioni'),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
            onPressed: () => context.push('/notifiche'),
          ),
        ],
      ),
      body: activeChatsAsync.when(
        data: (rides) {
          if (rides.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: AppColors.universityGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Nessuna chat attiva',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Le chat si attiveranno automaticamente non appena creerai una corsa o una tua prenotazione verrà accettata dal guidatore.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final currentUsername = ref.watch(userProfileProvider).value?.username;
              final isDriver = ride.driverUsername == currentUsername;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() {
                      _selectedRide = ride;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isDriver
                              ? AppColors.universityGreen.withValues(alpha: 0.15)
                              : Colors.blueAccent.withValues(alpha: 0.15),
                          child: Icon(
                            isDriver ? Icons.drive_eta : Icons.person_pin_circle,
                            color: isDriver ? AppColors.universityGreen : Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ride.departureCity} ➔ ${ride.arrivalCity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDriver
                                    ? 'La tua corsa (Guidatore)'
                                    : 'Autore: ${ride.driverFullName}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(ride.departureTime)} alle ${_formatTime(ride.departureTime)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ride.status == 'IN_PROGRESS'
                                ? Colors.orange.withValues(alpha: 0.2)
                                : AppColors.universityGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ride.status == 'IN_PROGRESS' ? 'In Corso' : 'Aperta',
                            style: TextStyle(
                              color: ride.status == 'IN_PROGRESS'
                                  ? Colors.orangeAccent
                                  : AppColors.universityGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.universityGreen),
        ),
        error: (err, stack) => Center(
          child: Text('Errore: $err'),
        ),
      ),
    );
  }

  Widget _buildChatDetail(Ride ride) {
    final currentUsername = ref.watch(userProfileProvider).value?.username;
    final messagesAsync = ref.watch(chatMessagesProvider(ride.id));
    final isDriver = ride.driverUsername == currentUsername;

    // Trigger auto-scroll on new data
    ref.listen(chatMessagesProvider(ride.id), (previous, next) {
      next.whenData((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      });
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedRide = null;
            });
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('${ride.departureCity} ➔ ${ride.arrivalCity}'),
            Text(
              isDriver ? 'Gruppo Corsa' : 'Autista: ${ride.driverFullName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              ref.invalidate(chatMessagesProvider(ride.id));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'Nessun messaggio ancora',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDriver
                              ? 'Scrivi un messaggio per salutare i passeggeri!'
                              : 'Scrivi un messaggio per metterti d\'accordo con l\'autista!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUsername == currentUsername;
                    final isMsgDriver = msg.senderUsername == ride.driverUsername;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                child: Text(
                                  '${msg.senderFullName} ${isMsgDriver ? "(Driver)" : ""}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.universityGreen
                                    : AppColors.cardDark,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 20),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg.latitude != null && msg.longitude != null) ...[
                                    const Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Posizione GPS condivisa',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _openMap(msg.latitude!, msg.longitude!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black26,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(Icons.map, size: 16),
                                      label: const Text('Copia Coordinate', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    msg.content,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTime(msg.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.universityGreen),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Impossibile caricare i messaggi: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ),
          _buildInputBar(ride),
        ],
      ),
    );
  }

  Widget _buildInputBar(Ride ride) {
    final isMeDriver = ride.driverUsername == ref.watch(userProfileProvider).value?.username;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.charcoal,
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isMeDriver) // Only passengers typically send current location to the driver
              IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.universityGreen),
                tooltip: 'Condividi posizione',
                onPressed: _shareLocation,
              ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Scrivi un messaggio...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.universityGreen, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.universityGreen,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMap(double latitude, double longitude) async {
    final coordinateString = '$latitude, $longitude';
    
    // 1. Copy to Clipboard (using native Services)
    await Clipboard.setData(ClipboardData(text: coordinateString));

    // 2. Launch external maps application
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$latitude,$longitude");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("No map application available");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinate copiate: $coordinateString. Incolla sulle mappe per visualizzare.'),
          backgroundColor: AppColors.universityGreen,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Oggi';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Domani';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
