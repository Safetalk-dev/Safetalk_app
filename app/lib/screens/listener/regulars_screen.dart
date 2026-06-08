import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class ListenerRegularsScreen extends StatelessWidget {
  final VoidCallback onStartSession;

  const ListenerRegularsScreen({
    super.key,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    // Regular Seekers directory mockup
    final List<Map<String, dynamic>> seekers = [
      {
        'moniker': 'Pine Pebble #107',
        'sessions': 8,
        'lastActive': 'May 24th',
        'primaryConcern': 'Academic Pressure & Imposter Syndrome',
        'notes': 'Struggles with perfectionism. We worked on cognitive restructuring, validating effort over outcome.',
        'color': SafeTalkTheme.brandTerracotta,
      },
      {
        'moniker': 'Mist Pebble #44',
        'sessions': 5,
        'lastActive': 'May 23rd',
        'primaryConcern': 'Workplace Burnout & Boundaries',
        'notes': 'Spoke about setting boundaries with working weekend hours. Encouraged saying "no" firmly and cleanly.',
        'color': SafeTalkTheme.brandSageLight,
      },
      {
        'moniker': 'Forest Breeze #99',
        'sessions': 12,
        'lastActive': 'May 18th',
        'primaryConcern': 'Social Isolation / Relocation Anxiety',
        'notes': 'Spoke about loneliness after moving. Explored local community connections and joining interest clubs.',
        'color': SafeTalkTheme.brandGold,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            'My Seeker Circle',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            'Seekers you\'ve held space for. Keeping sessions anonymous and secure.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),

          const SizedBox(height: 28),

          // Seekers List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: seekers.length,
              itemBuilder: (context, index) {
                final seeker = seekers[index];
                return Padding(
                  key: ValueKey(seeker['moniker']),
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
                              backgroundColor: seeker['color'].withValues(alpha: 0.12),
                              child: Icon(Icons.psychology, color: seeker['color'], size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seeker['moniker'],
                                    style: SafeTalkTheme.bodyStyle(
                                      color: SafeTalkTheme.textPrimary,
                                      bold: true,
                                    ).copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${seeker['sessions']} sessions total',
                                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Last spoke: ${seeker['lastActive']}',
                                        style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: SafeTalkTheme.borderSage, height: 1),
                        const SizedBox(height: 16),

                        // Primary concern info
                        Text(
                          'PRIMARY CONCERN:  ',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seeker['primaryConcern'],
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                              .copyWith(fontSize: 14),
                        ),
                        
                        const SizedBox(height: 12),

                        // Encrypted journal note snippet
                        Text(
                          'ENCRYPTED JOURNAL NOTES SUMMARY:  ',
                          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seeker['notes'],
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)
                              .copyWith(fontSize: 13.5, height: 1.4),
                        ),

                        const SizedBox(height: 20),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onStartSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeTalkTheme.brandSage,
                              foregroundColor: SafeTalkTheme.bgMidnight,
                              shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.forum_rounded, size: 16),
                            label: Text(
                              'Open Chat Workspace',
                              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
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
  }
}
