import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../controllers/session_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/haptic_touchable.dart';
import '../../widgets/pin_sheet.dart';

class HistoryScreen extends StatefulWidget {
  final bool isSeeker; // true if seeker, false if listener/therapist

  const HistoryScreen({super.key, required this.isSeeker});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // List of past sessions
  final List<Map<String, dynamic>> _pastSessions = [];

  void _showSessionDetail(Map<String, dynamic> session) {
    if (session['type'] == 'Secure Chat Support') {
      // Synchronize with ChatController in real-time
      final nameToFind = session['name'] ?? (widget.isSeeker ? 'Listener' : 'Seeker');
      final threads = widget.isSeeker 
          ? ChatController().userThreads 
          : ChatController().listenerThreads;
      final matchingThread = threads.firstWhere(
        (t) => t['name'] == nameToFind,
        orElse: () => <String, dynamic>{},
      );
      if (matchingThread.isNotEmpty) {
        session['messages'] = matchingThread['messages'];
        session['notes'] = matchingThread['notes'];
      }

      // Chat session → open chat history transcript screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatHistoryTranscriptScreen(
            session: session,
            isSeeker: widget.isSeeker,
          ),
        ),
      );
    } else {
      // Call session → open call history transcript screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallHistoryTranscriptScreen(
            session: session,
            isSeeker: widget.isSeeker,
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = widget.isSeeker
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = widget.isSeeker
        ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.8)
        : SafeTalkTheme.getListenerColorLight(isTherapist);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAST COUNSELING LOGS',
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Icon(Icons.shield_outlined, color: brandColorLight, size: 16),
              ],
            ),
          ),
          Expanded(
            child: _pastSessions.isEmpty
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
                              Icons.history_rounded,
                              color: brandColorLight,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Session History Yet',
                            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isSeeker
                                ? 'Completed support sessions and consultation transcripts will appear here.'
                                : 'Completed counseling sessions with seekers will be securely logged here.',
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _pastSessions.length,
                    itemBuilder: (context, index) {
                      final session = _pastSessions[index];
                      final displayName = widget.isSeeker ? session['name'] : session['seekerName'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: HapticTouchable(
                    onTap: () => _showSessionDetail(session),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: SafeTalkTheme.glassCardDecoration,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: session['isPremium']
                                ? SafeTalkTheme.brandGold.withValues(alpha: 0.15)
                                : brandColor.withValues(alpha: 0.15),
                            child: Icon(
                              session['icon'],
                              color: session['isPremium'] ? SafeTalkTheme.brandGold : brandColorLight,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${session['type']} • ${session['id']}',
                                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session['date'],
                                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textMuted).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.isSeeker
                                    ? '-₹${session['amount'].toStringAsFixed(0)}'
                                    : '+₹${session['amount'].toStringAsFixed(0)}',
                                style: SafeTalkTheme.bodyStyle(
                                  color: session['isPremium'] ? SafeTalkTheme.brandGold : brandColorLight,
                                  bold: true,
                                ).copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  final isFilled = starIndex < session['rating'];
                                  return Icon(
                                    isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: SafeTalkTheme.brandGold,
                                    size: 10,
                                  );
                                }),
                              ),
                            ],
                          ),
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

// ─── CHAT HISTORY TRANSCRIPT VIEW SCREEN ─────────────────────────────────────

class ChatHistoryTranscriptScreen extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isSeeker;

  const ChatHistoryTranscriptScreen({
    super.key,
    required this.session,
    required this.isSeeker,
  });

  void _showNotesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController notesController = TextEditingController(text: session['notes'] ?? '');
        bool isEditing = false;
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            final isTherapist = SessionController().isTherapist;
            final brandColor = isSeeker
                ? SafeTalkTheme.brandTerracotta
                : SafeTalkTheme.getListenerColor(isTherapist);
            
            final double drawerHeight = isKeyboardOpen 
                ? (screenHeight - MediaQuery.of(context).viewInsets.bottom - 40)
                : (screenHeight * 0.7);

            final double textFieldHeight = isKeyboardOpen
                ? screenHeight * 0.18
                : screenHeight * 0.30;

            final bool isLocked = !isSeeker && ChatController().isVaultEnabled && ChatController().userPin == null;

            return Container(
              width: double.infinity,
              height: drawerHeight,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: isKeyboardOpen ? 24 : 40,
              ),
              decoration: BoxDecoration(
                color: SafeTalkTheme.cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isSeeker ? 'Secure Session Journal' : 'Secure Session Notes',
                          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: SafeTalkTheme.textSecondary),
                        onPressed: () {
                          if (ChatController().isVaultEnabled) {
                            ChatController().lockVault();
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSeeker
                        ? 'Your private, encrypted reflections and journals for this session.'
                        : 'Confidential session records for ${session['seekerName']}. Locked securely inside the Vault.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLocked) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: brandColor.withValues(alpha: 0.12),
                                    ),
                                    child: Icon(
                                      Icons.lock_person_rounded,
                                      color: brandColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Encrypted Journal is Locked',
                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                                        .copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'To protect seeker confidentiality, this journal is sealed with a PIN-derived encryption key. Decryption keys are held in volatile memory only.',
                                      textAlign: TextAlign.center,
                                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: HapticTouchable(
                                      onTap: () {
                                        PinSheet.show(
                                          context: context,
                                          mode: PinSheetMode.unlock,
                                          onSuccess: (pin) {
                                            setSheetState(() {});
                                          },
                                        );
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: brandColor,
                                          borderRadius: SafeTalkTheme.organicCardRadius,
                                        ),
                                        child: Text(
                                          'Unlock Session Notes',
                                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            if (!isEditing) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: SafeTalkTheme.glassCardDecoration,
                                child: Text(
                                  session['notes'] ?? (isSeeker ? 'No journal entries logged for this session.' : 'No notes compiled for this session.'),
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary)
                                      .copyWith(fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setSheetState(() {
                                      isEditing = true;
                                    });
                                  },
                                  icon: const Icon(Icons.edit_rounded, size: 16),
                                  label: Text(isSeeker ? 'Edit Journal' : 'Edit Notes'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: brandColor,
                                    side: BorderSide(color: brandColor),
                                    shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                                  ),
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                height: textFieldHeight,
                                child: TextField(
                                  controller: notesController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: isSeeker ? 'Write down your thoughts, breakthroughs, and reflections...' : 'Add counseling notes or reminders...',
                                    hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                                    filled: true,
                                    fillColor: SafeTalkTheme.bgMidnight,
                                    contentPadding: const EdgeInsets.all(16),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: SafeTalkTheme.standardRadius,
                                      borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: SafeTalkTheme.standardRadius,
                                      borderSide: BorderSide(color: brandColor, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setSheetState(() {
                                          isEditing = false;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: SafeTalkTheme.textSecondary,
                                        side: const BorderSide(color: SafeTalkTheme.borderSage),
                                        shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        session['notes'] = notesController.text;
                                        if (isSeeker) {
                                          ChatController().saveUserNotes(session['name'] ?? '', notesController.text);
                                        } else {
                                          final seekerName = session['seekerName'] ?? session['name'] ?? 'Pine Pebble #107';
                                          ChatController().saveListenerNotes(seekerName, notesController.text);
                                          if (ChatController().isVaultEnabled) {
                                            ChatController().lockVault();
                                          }
                                        }
                                        setSheetState(() {
                                          isEditing = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isSeeker ? 'Session journal securely saved.' : 'Session notes securely saved.',
                                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
                                            ),
                                            backgroundColor: brandColor,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: brandColor,
                                        foregroundColor: SafeTalkTheme.bgMidnight,
                                        shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                                      ),
                                      child: const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = isSeeker
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = isSeeker
        ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.8)
        : SafeTalkTheme.getListenerColorLight(isTherapist);

    final rawMessages = session['messages'] as List?;
    final messages = rawMessages?.map((m) => Map<String, String>.from(m as Map)).toList() ?? <Map<String, String>>[];
    final displayName = isSeeker ? (session['name'] ?? '') : (session['seekerName'] ?? session['name'] ?? '');

    return Scaffold(
      backgroundColor: SafeTalkTheme.bgMidnight,
      body: Stack(
        children: [
          // Ambiance gradients
          Positioned(
            top: -120,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: brandColor.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: CircleAvatar(
              radius: 250,
              backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.03),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Header Bar - Redesigned to be Premium, Floating & Uncluttered
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  margin: const EdgeInsets.all(16),
                  decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: brandColor.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: SafeTalkTheme.textPrimary, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: session['isPremium'] == true
                            ? SafeTalkTheme.brandGold.withValues(alpha: 0.15)
                            : brandColor.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: session['isPremium'] == true ? SafeTalkTheme.brandGold : brandColorLight,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.security, color: brandColorLight, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Archived Private Transcript',
                                    style: SafeTalkTheme.captionStyle(color: brandColorLight).copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Premium notes/journals toggle button (visible to both listener and seeker)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isSeeker ? Icons.history_edu_outlined : Icons.note_alt_outlined,
                            color: brandColorLight,
                            size: 18,
                          ),
                          tooltip: isSeeker ? 'Secure Session Journal' : 'Secure Session Notes',
                          onPressed: () => _showNotesBottomSheet(context),
                        ),
                      ),
                      // Premium styled Rating badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: SafeTalkTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SafeTalkTheme.brandGold.withValues(alpha: 0.4), width: 1.2),
                          boxShadow: SafeTalkTheme.glowShadow(SafeTalkTheme.brandGold, opacity: 0.1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: SafeTalkTheme.brandGold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              (session['rating'] is num)
                                  ? (session['rating'] as num).toStringAsFixed(1)
                                  : '5.0',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Chat transcript content list
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // Determine if message is from the logged-in viewer
                      final isMe = isSeeker
                          ? msg['sender'] == 'user'
                          : msg['sender'] == 'listener';

                      final radius = isMe
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(4),
                              topRight: Radius.circular(20),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(4),
                            );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: brandColor.withValues(alpha: 0.2),
                                child: Text(
                                  displayName[0],
                                  style: SafeTalkTheme.captionStyle(color: brandColor).copyWith(fontSize: 9),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? brandColor : SafeTalkTheme.cardBg,
                                  borderRadius: radius,
                                  border: isMe
                                      ? null
                                      : Border.all(color: SafeTalkTheme.borderSage, width: 1.2),
                                ),
                                child: Text(
                                  msg['text']!,
                                  style: SafeTalkTheme.bodyStyle(
                                    color: isMe ? SafeTalkTheme.bgMidnight : SafeTalkTheme.textPrimary,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Encryption lock notice strictly at the bottom
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, color: SafeTalkTheme.brandSage.withValues(alpha: 0.5), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'This chat record remains locked and zero-trace.',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CALL HISTORY TRANSCRIPT VIEW SCREEN ─────────────────────────────────────

class CallHistoryTranscriptScreen extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isSeeker;

  const CallHistoryTranscriptScreen({
    super.key,
    required this.session,
    required this.isSeeker,
  });

  void _showNotesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController notesController = TextEditingController(text: session['notes'] ?? '');
        bool isEditing = false;
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final double screenHeight = MediaQuery.of(context).size.height;
            final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            final isTherapist = SessionController().isTherapist;
            final brandColor = isSeeker
                ? SafeTalkTheme.brandTerracotta
                : SafeTalkTheme.getListenerColor(isTherapist);
            
            final double drawerHeight = isKeyboardOpen 
                ? (screenHeight - MediaQuery.of(context).viewInsets.bottom - 40)
                : (screenHeight * 0.7);

            final double textFieldHeight = isKeyboardOpen
                ? screenHeight * 0.18
                : screenHeight * 0.30;

            final bool isLocked = !isSeeker && ChatController().isVaultEnabled && ChatController().userPin == null;

            return Container(
              width: double.infinity,
              height: drawerHeight,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: isKeyboardOpen ? 24 : 40,
              ),
              decoration: BoxDecoration(
                color: SafeTalkTheme.cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isSeeker ? 'Secure Session Journal' : 'Secure Session Notes',
                          style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: SafeTalkTheme.textSecondary),
                        onPressed: () {
                          if (ChatController().isVaultEnabled) {
                            ChatController().lockVault();
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSeeker
                        ? 'Your private, encrypted reflections and journals for this session.'
                        : 'Confidential session records for ${session['seekerName']}. Locked securely inside the Vault.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLocked) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: brandColor.withValues(alpha: 0.12),
                                    ),
                                    child: Icon(
                                      Icons.lock_person_rounded,
                                      color: brandColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Encrypted Journal is Locked',
                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                                        .copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'To protect seeker confidentiality, this journal is sealed with a PIN-derived encryption key. Decryption keys are held in volatile memory only.',
                                      textAlign: TextAlign.center,
                                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: HapticTouchable(
                                      onTap: () {
                                        PinSheet.show(
                                          context: context,
                                          mode: PinSheetMode.unlock,
                                          onSuccess: (pin) {
                                            setSheetState(() {});
                                          },
                                        );
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: brandColor,
                                          borderRadius: SafeTalkTheme.organicCardRadius,
                                        ),
                                        child: Text(
                                          'Unlock Session Notes',
                                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            if (!isEditing) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: SafeTalkTheme.glassCardDecoration,
                                child: Text(
                                  session['notes'] ?? (isSeeker ? 'No journal entries logged for this session.' : 'No notes compiled for this session.'),
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary)
                                      .copyWith(fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setSheetState(() {
                                      isEditing = true;
                                    });
                                  },
                                  icon: const Icon(Icons.edit_rounded, size: 16),
                                  label: Text(isSeeker ? 'Edit Journal' : 'Edit Notes'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: brandColor,
                                    side: BorderSide(color: brandColor),
                                    shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                                  ),
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                height: textFieldHeight,
                                child: TextField(
                                  controller: notesController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: isSeeker ? 'Write down your thoughts, breakthroughs, and reflections...' : 'Add counseling notes or reminders...',
                                    hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                                    filled: true,
                                    fillColor: SafeTalkTheme.bgMidnight,
                                    contentPadding: const EdgeInsets.all(16),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: SafeTalkTheme.standardRadius,
                                      borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: SafeTalkTheme.standardRadius,
                                      borderSide: BorderSide(color: brandColor, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setSheetState(() {
                                          isEditing = false;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: SafeTalkTheme.textSecondary,
                                        side: const BorderSide(color: SafeTalkTheme.borderSage),
                                        shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        session['notes'] = notesController.text;
                                        if (isSeeker) {
                                          ChatController().saveUserNotes(session['name'] ?? '', notesController.text);
                                        } else {
                                          final seekerName = session['seekerName'] ?? session['name'] ?? 'Pine Pebble #107';
                                          ChatController().saveListenerNotes(seekerName, notesController.text);
                                          if (ChatController().isVaultEnabled) {
                                            ChatController().lockVault();
                                          }
                                        }
                                        setSheetState(() {
                                          isEditing = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isSeeker ? 'Session journal securely saved.' : 'Session notes securely saved.',
                                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight),
                                            ),
                                            backgroundColor: brandColor,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: brandColor,
                                        foregroundColor: SafeTalkTheme.bgMidnight,
                                        shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                                      ),
                                      child: const Text('Save Changes'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = SessionController().isTherapist;
    final brandColor = isSeeker
        ? SafeTalkTheme.brandTerracotta
        : SafeTalkTheme.getListenerColor(isTherapist);
    final brandColorLight = isSeeker
        ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.8)
        : SafeTalkTheme.getListenerColorLight(isTherapist);

    final displayName = isSeeker ? (session['name'] ?? '') : (session['seekerName'] ?? session['name'] ?? '');

    return Scaffold(
      backgroundColor: SafeTalkTheme.bgMidnight,
      body: Stack(
        children: [
          // Ambiance gradients
          Positioned(
            top: -120,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: brandColor.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: CircleAvatar(
              radius: 250,
              backgroundColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.03),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  margin: const EdgeInsets.all(16),
                  decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: brandColor.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: SafeTalkTheme.textPrimary, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: session['isPremium'] == true
                            ? SafeTalkTheme.brandGold.withValues(alpha: 0.15)
                            : brandColor.withValues(alpha: 0.15),
                        child: Icon(
                          session['icon'] ?? Icons.phone_rounded,
                          color: session['isPremium'] == true ? SafeTalkTheme.brandGold : brandColorLight,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.security, color: brandColorLight, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Archived Secure Call Log',
                                    style: SafeTalkTheme.captionStyle(color: brandColorLight).copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Notes button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isSeeker ? Icons.history_edu_outlined : Icons.note_alt_outlined,
                            color: brandColorLight,
                            size: 18,
                          ),
                          tooltip: isSeeker ? 'Secure Session Journal' : 'Secure Session Notes',
                          onPressed: () => _showNotesBottomSheet(context),
                        ),
                      ),
                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: SafeTalkTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SafeTalkTheme.brandGold.withValues(alpha: 0.4), width: 1.2),
                          boxShadow: SafeTalkTheme.glowShadow(SafeTalkTheme.brandGold, opacity: 0.1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: SafeTalkTheme.brandGold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              (session['rating'] is num)
                                  ? (session['rating'] as num).toStringAsFixed(1)
                                  : '5.0',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Call session stats grid
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Call session card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: SafeTalkTheme.glassCardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: brandColor.withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    session['icon'] ?? Icons.phone_rounded,
                                    color: brandColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  session['type'] ?? 'Voice Call Support',
                                  style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 20),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Completed Session • ${session['id']}',
                                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(color: SafeTalkTheme.borderSage, height: 1),
                              const SizedBox(height: 24),
                              _buildStatItem('Companion Name', isSeeker ? (session['name'] ?? 'Listener') : 'You (Listener)'),
                              const SizedBox(height: 14),
                              _buildStatItem('Seeker Pseudonym', isSeeker ? 'You (Seeker)' : (session['seekerName'] ?? 'Anonymous Seeker')),
                              const SizedBox(height: 14),
                              _buildStatItem('Call Duration', session['duration'] ?? '15 minutes'),
                              const SizedBox(height: 14),
                              _buildStatItem('Date & Time', session['date'] ?? 'Just now'),
                              const SizedBox(height: 14),
                              _buildStatItem(
                                'Billed Amount',
                                isSeeker
                                    ? '-₹${(session['amount'] ?? 150.0).toStringAsFixed(0)}'
                                    : '+₹${(session['amount'] ?? 150.0).toStringAsFixed(0)}',
                                highlightColor: session['isPremium'] == true ? SafeTalkTheme.brandGold : brandColorLight,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Quick reflections summary preview
                        Text(
                          'SESSION SUMMARY',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: SafeTalkTheme.glassCardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session['notes'] ?? (isSeeker ? 'No journal entry has been compiled yet.' : 'No notes have been logged yet.'),
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary).copyWith(
                                  height: 1.4,
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: brandColor,
                                ),
                                icon: Icon(
                                  isSeeker ? Icons.history_edu_outlined : Icons.note_alt_outlined,
                                  size: 16,
                                ),
                                label: Text(isSeeker ? 'Manage Secure Journal' : 'Manage Confidential Notes'),
                                onPressed: () => _showNotesBottomSheet(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Encryption lock notice strictly at the bottom
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, color: SafeTalkTheme.brandSage.withValues(alpha: 0.5), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'This call record remains locked and zero-trace.',
                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)),
        Text(
          value,
          style: SafeTalkTheme.bodyStyle(
            color: highlightColor ?? SafeTalkTheme.textPrimary,
            bold: true,
          ),
        ),
      ],
    );
  }
}


