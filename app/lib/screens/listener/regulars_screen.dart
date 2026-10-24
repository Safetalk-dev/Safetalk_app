import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/tokens.dart';

class ListenerRegularsScreen extends StatelessWidget {
  final VoidCallback onStartSession;

  const ListenerRegularsScreen({super.key, required this.onStartSession});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Stream<List<Map<String, dynamic>>> _streamRegularSeekers(String listenerUid) {
    if (listenerUid.isEmpty) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('sessions')
        .where('listenerId', isEqualTo: listenerUid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          final Map<String, Map<String, dynamic>> seekerMap = {};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final seekerId = data['seekerId'] as String? ?? doc.id;
            final moniker =
                data['seekerMoniker'] as String? ?? 'Anonymous Seeker';
            final concern =
                data['seekerMoodTag'] as String? ?? 'General Support';
            final notes =
                data['notes'] as String? ??
                'Past counseling session completed anonymously and kept in confidence.';

            DateTime dt = DateTime.now();
            final rawDate =
                data['completedAt'] ?? data['updatedAt'] ?? data['createdAt'];
            if (rawDate is Timestamp) {
              dt = rawDate.toDate();
            } else if (rawDate is String) {
              dt = DateTime.tryParse(rawDate) ?? dt;
            }

            if (!seekerMap.containsKey(seekerId)) {
              seekerMap[seekerId] = {
                'seekerId': seekerId,
                'moniker': moniker,
                'sessions': 1,
                'lastActiveDt': dt,
                'primaryConcern': concern,
                'notes': notes,
                'color': SafeTalkTheme.brandSage,
              };
            } else {
              seekerMap[seekerId]!['sessions'] =
                  (seekerMap[seekerId]!['sessions'] as int) + 1;
              if (dt.isAfter(
                seekerMap[seekerId]!['lastActiveDt'] as DateTime,
              )) {
                seekerMap[seekerId]!['lastActiveDt'] = dt;
                seekerMap[seekerId]!['primaryConcern'] = concern;
              }
            }
          }

          final list = seekerMap.values.map((s) {
            s['lastActive'] = _formatDate(s['lastActiveDt'] as DateTime);
            return s;
          }).toList();

          list.sort(
            (a, b) => (b['lastActiveDt'] as DateTime).compareTo(
              a['lastActiveDt'] as DateTime,
            ),
          );
          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _streamRegularSeekers(uid),
      builder: (context, snapshot) {
        final seekers = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Text(
                'My Seeker Circle',
                style: SafeTalkTheme.displayStyle(
                  color: SafeTalkTheme.textPrimary,
                ).copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                'Seekers you\'ve held space for. Keeping sessions anonymous and secure.',
                style: SafeTalkTheme.bodyStyle(
                  color: SafeTalkTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // Seekers List
              Expanded(
                child: seekers.isEmpty
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
                                  border: Border.all(
                                    color: SafeTalkTheme.borderSage,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.psychology_outlined,
                                  color: SafeTalkTheme.brandSage,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No Seekers in Your Circle',
                                style: SafeTalkTheme.headingStyle(
                                  color: SafeTalkTheme.textPrimary,
                                ).copyWith(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When you complete repeat sessions with anonymous seekers, they will appear here with encrypted journal notes.',
                                style: SafeTalkTheme.bodyStyle(
                                  color: SafeTalkTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: seekers.length,
                        itemBuilder: (context, index) {
                          final seeker = seekers[index];
                          return Padding(
                            key: ValueKey(seeker['seekerId']),
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: SafeTalkTheme.glassCardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header details
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            (seeker['color'] as Color)
                                                .withValues(alpha: 0.12),
                                        child: Icon(
                                          Icons.psychology,
                                          color: seeker['color'] as Color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              seeker['moniker'] as String,
                                              style: SafeTalkTheme.bodyStyle(
                                                color:
                                                    SafeTalkTheme.textPrimary,
                                                bold: true,
                                              ).copyWith(fontSize: 16),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  '${seeker['sessions']} sessions total',
                                                  style:
                                                      SafeTalkTheme.captionStyle(
                                                        color: SafeTalkTheme
                                                            .brandSageLight,
                                                      ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Last spoke: ${seeker['lastActive']}',
                                                  style:
                                                      SafeTalkTheme.captionStyle(
                                                        color: SafeTalkTheme
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  const Divider(
                                    color: SafeTalkTheme.borderSage,
                                    height: 1,
                                  ),
                                  const SizedBox(height: 16),

                                  // Primary concern info
                                  Text(
                                    'PRIMARY CONCERN:  ',
                                    style: SafeTalkTheme.captionStyle(
                                      color: SafeTalkTheme.textSecondary,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    seeker['primaryConcern'] as String,
                                    style: SafeTalkTheme.bodyStyle(
                                      color: SafeTalkTheme.textPrimary,
                                      bold: true,
                                    ).copyWith(fontSize: 14),
                                  ),

                                  const SizedBox(height: 12),

                                  // Encrypted journal note snippet
                                  Text(
                                    'CONFIDENTIAL SUMMARY:  ',
                                    style: SafeTalkTheme.captionStyle(
                                      color: SafeTalkTheme.brandSageLight,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    seeker['notes'] as String,
                                    style: SafeTalkTheme.bodyStyle(
                                      color: SafeTalkTheme.textSecondary,
                                    ).copyWith(fontSize: 13.5, height: 1.4),
                                  ),

                                  const SizedBox(height: 20),

                                  // Action button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: onStartSession,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            SafeTalkTheme.brandSage,
                                        foregroundColor:
                                            SafeTalkTheme.bgMidnight,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              SafeTalkTheme.organicCardRadius,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.forum_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        'Open Chat Workspace',
                                        style: SafeTalkTheme.bodyStyle(
                                          color: SafeTalkTheme.bgMidnight,
                                          bold: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
