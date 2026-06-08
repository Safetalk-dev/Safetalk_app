import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/chat_controller.dart';
import '../shared/session_chat_screen.dart';
import '../shared/history_screen.dart';

class UserMessagesScreen extends StatefulWidget {
  final String? initialChatPartner;
  const UserMessagesScreen({super.key, this.initialChatPartner});

  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  @override
  void initState() {
    super.initState();
    ChatController().addListener(_onChatControllerChanged);
    
    // Pre-open a specific thread if provided
    if (widget.initialChatPartner != null) {
      ChatController().markUserThreadRead(widget.initialChatPartner!);
      Future.microtask(() {
        if (!mounted) return;
        final threads = ChatController().userThreads;
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
                  partnerName: thread['name'],
                  isSeeker: true,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatHistoryTranscriptScreen(
                  session: thread,
                  isSeeker: true,
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
    super.dispose();
  }

  void _onChatControllerChanged() {
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
    final threads = ChatController().userThreads;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safe Channels',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'All conversations are double-encrypted and deleted after 30 days.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          
          const SizedBox(height: 24),

          // Search thread mockup
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: SafeTalkTheme.cardBg,
              borderRadius: SafeTalkTheme.pillRadius,
              border: Border.all(color: SafeTalkTheme.borderSage, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: SafeTalkTheme.textSecondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search encrypted channels...',
                      hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Thread list builder
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return Padding(
                  key: ValueKey(thread['name']),
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      ChatController().markUserThreadRead(thread['name']);
                      final isActive = thread['status'].toString().toLowerCase().contains('active');
                      if (isActive) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionChatScreen(
                              partnerName: thread['name'],
                              isSeeker: true,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatHistoryTranscriptScreen(
                              session: thread,
                              isSeeker: true,
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
                              ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.3)
                              : SafeTalkTheme.borderSage,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Custom Avatar with status dot
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: thread['avatarColor'].withValues(alpha: 0.2),
                                child: Text(
                                  thread['name'][0],
                                  style: SafeTalkTheme.headingStyle(color: thread['avatarColor']),
                                ),
                              ),
                              if (thread['online'])
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    height: 12,
                                    width: 12,
                                    decoration: BoxDecoration(
                                      color: SafeTalkTheme.brandSage,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: SafeTalkTheme.bgMidnight, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Thread text
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
                              decoration: const BoxDecoration(
                                color: SafeTalkTheme.brandTerracotta,
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
