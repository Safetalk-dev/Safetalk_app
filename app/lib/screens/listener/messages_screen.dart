import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/session_controller.dart';
import '../shared/session_chat_screen.dart';
import '../shared/history_screen.dart';

class ListenerMessagesScreen extends StatefulWidget {
  final String? initialChatPartner;
  const ListenerMessagesScreen({super.key, this.initialChatPartner});

  @override
  State<ListenerMessagesScreen> createState() => _ListenerMessagesScreenState();
}

class _ListenerMessagesScreenState extends State<ListenerMessagesScreen> {
  @override
  void initState() {
    super.initState();
    ChatController().addListener(_onChatControllerChanged);
    SessionController().addListener(_onSessionChanged);
    
    if (widget.initialChatPartner != null) {
      ChatController().markListenerThreadRead(widget.initialChatPartner!);
      Future.microtask(() {
        if (!mounted) return;
        final threads = ChatController().listenerThreads;
        final thread = threads.firstWhere(
          (t) => t['name'] == widget.initialChatPartner,
          orElse: () => threads.isNotEmpty ? threads[0] : <String, dynamic>{},
        );
        if (thread.isNotEmpty) {
          final isActive = thread['status'].toString().toLowerCase().contains('active');
          if (isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionChatScreen(
                  sessionId: thread['id'] ?? '',
                  myUid: SessionController().firebaseUid ?? '',
                  partnerName: thread['name']!,
                  isSeeker: false,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatHistoryTranscriptScreen(
                  session: thread,
                  isSeeker: false,
                ),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    ChatController().removeListener(_onChatControllerChanged);
    SessionController().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onChatControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeTalkTheme.bgMidnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: SafeTalkTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: SafeTalkTheme.ambientBackground,
        child: SafeArea(
          bottom: false,
          child: _buildThreadListView(),
        ),
      ),
    );
  }

  Widget _buildThreadListView() {
    final threads = ChatController().listenerThreads;
    final isTherapist = SessionController().isTherapist;
    final brandColor = SafeTalkTheme.getListenerColor(isTherapist);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seeker Channels',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep counselor journal notes locally encrypted within the secure vault.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          
          const SizedBox(height: 24),

          // Thread list builder
          Expanded(
            child: threads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: SafeTalkTheme.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
                            ),
                            child: Icon(
                              Icons.forum_outlined,
                              color: brandColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Seeker Channels',
                            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Active chat channels with anonymous seekers will appear here.',
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return Padding(
                        key: ValueKey(thread['name']),
                        padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      ChatController().markListenerThreadRead(thread['name']);
                      final isActive = thread['status'].toString().toLowerCase().contains('active');
                      if (isActive) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionChatScreen(
                              sessionId: thread['id'] ?? '',
                              myUid: SessionController().firebaseUid ?? '',
                              partnerName: thread['name']!,
                              isSeeker: false,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatHistoryTranscriptScreen(
                              session: thread,
                              isSeeker: false,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                        border: Border.all(
                          color: thread['unread']
                              ? brandColor.withValues(alpha: 0.3)
                              : SafeTalkTheme.borderSage,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Custom Seeker Silhouette Avatar with online indicator dot
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: thread['avatarColor'].withValues(alpha: 0.2),
                                child: Icon(Icons.psychology, color: thread['avatarColor'], size: 24),
                              ),
                              if (thread['online'])
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    height: 12,
                                    width: 12,
                                    decoration: BoxDecoration(
                                      color: brandColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: SafeTalkTheme.bgMidnight, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Thread text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      thread['name'],
                                      style: SafeTalkTheme.bodyStyle(
                                        color: SafeTalkTheme.textPrimary,
                                        bold: true,
                                      ).copyWith(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Text(
                                      thread['time'],
                                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  thread['lastMessage'],
                                  style: SafeTalkTheme.bodyStyle(
                                    color: thread['unread'] ? SafeTalkTheme.textPrimary : SafeTalkTheme.textSecondary,
                                    bold: thread['unread'],
                                  ).copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          if (thread['unread']) ...[
                            const SizedBox(width: 12),
                            Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: brandColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
