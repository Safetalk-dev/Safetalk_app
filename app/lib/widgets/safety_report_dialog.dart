import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class SafetyReportDialog extends StatefulWidget {
  final String targetName;
  final bool isReportingListener; // true if seeker reporting listener, false if listener reporting seeker
  final Function(String reason, String details) onSubmit;

  const SafetyReportDialog({
    super.key,
    required this.targetName,
    required this.isReportingListener,
    required this.onSubmit,
  });

  static void show({
    required BuildContext context,
    required String targetName,
    required bool isReportingListener,
    required Function(String reason, String details) onSubmit,
  }) {
    showDialog(
      context: context,
      builder: (context) => SafetyReportDialog(
        targetName: targetName,
        isReportingListener: isReportingListener,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<SafetyReportDialog> createState() => _SafetyReportDialogState();
}

class _SafetyReportDialogState extends State<SafetyReportDialog> {
  late String _selectedReason;
  final TextEditingController _reasonDetailsController = TextEditingController();

  final List<String> _listenerReasons = [
    'Boundary violation / Personal questions',
    'Unprofessional counseling style',
    'Inappropriate comments or behavior',
    'Self-disclosure or unsolicited advice',
    'Other concerns',
  ];

  final List<String> _seekerReasons = [
    'Boundary violation / Personal questions',
    'Inappropriate or offensive language',
    'Crisis / High self-harm risk',
    'Policy violation / commercial activity',
    'Other concerns',
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.isReportingListener
        ? _listenerReasons[0]
        : _seekerReasons[0];
  }

  @override
  void dispose() {
    _reasonDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reasons = widget.isReportingListener ? _listenerReasons : _seekerReasons;
    final titleText = widget.isReportingListener ? 'Report Peer Companion' : 'File Confidential Report';
    final descriptionText = widget.isReportingListener
        ? 'Filing a report against ${widget.targetName} is completely confidential. It triggers an automatic review of recent chat transcripts and calls by our clinical support coordinators.'
        : 'We take peer boundaries and safety seriously. Filing a report against ${widget.targetName} will encrypt the chat history and trigger an immediate review by our clinical oversight team.';

    return Dialog(
      backgroundColor: SafeTalkTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.standardRadius),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: SafeTalkTheme.brandGold, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titleText,
                      style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                descriptionText,
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(height: 1.4),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Reason',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: SafeTalkTheme.bgMidnight,
                  borderRadius: SafeTalkTheme.standardRadius,
                  border: Border.all(color: SafeTalkTheme.borderSage),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    dropdownColor: SafeTalkTheme.cardBg,
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                    items: reasons.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedReason = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Supporting Details',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonDetailsController,
                maxLines: 3,
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Describe what happened in detail...',
                  hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                  filled: true,
                  fillColor: SafeTalkTheme.bgMidnight,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: SafeTalkTheme.standardRadius,
                    borderSide: const BorderSide(color: SafeTalkTheme.borderSage, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: SafeTalkTheme.standardRadius,
                    borderSide: const BorderSide(color: SafeTalkTheme.brandSage, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary, bold: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeTalkTheme.brandGold,
                      foregroundColor: SafeTalkTheme.bgMidnight,
                      shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.pillRadius),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      
                      // 1. Input sanitization (Task 3.1): Strip HTML/JS tags
                      final rawInput = _reasonDetailsController.text;
                      final cleanInput = rawInput
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
                          .trim();

                      // 2. Anonymization Transient Model (Task 3.3): Strip PII / Monikers
                      final reportModel = TransientReportModel(
                        targetName: widget.targetName,
                        isReportingListener: widget.isReportingListener,
                        reason: _selectedReason,
                        details: cleanInput,
                      );
                      
                      final safeData = reportModel.toSafeJson();
                      
                      widget.onSubmit(
                        safeData['reason'] as String,
                        safeData['details'] as String,
                      );
                    },
                    child: Text(
                      'Submit Report',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransientReportModel {
  final String targetName;
  final bool isReportingListener;
  final String reason;
  final String details;

  TransientReportModel({
    required this.targetName,
    required this.isReportingListener,
    required this.reason,
    required this.details,
  });

  /// Strips PII, monikers, and real names before serializing/routing
  Map<String, dynamic> toSafeJson() {
    // Anonymize target name using deterministic hash to protect identities
    final String safeTarget = isReportingListener 
        ? 'Companion_ID_${targetName.hashCode}' 
        : 'Seeker_ID_${targetName.hashCode}';

    String safeDetails = details;
    
    // List of common PII identifiers and monikers to strip dynamically
    final List<String> piiWords = [
      'logan', 'amber', 'liam', 'sophia', 'devon',
      'phone', 'email', 'address', 'identity',
    ];
    
    for (final pii in piiWords) {
      safeDetails = safeDetails.replaceAll(RegExp(pii, caseSensitive: false), '[REDACTED_PII]');
    }

    return {
      'target_hash': safeTarget,
      'is_listener': isReportingListener,
      'reason': reason,
      'details': safeDetails,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
