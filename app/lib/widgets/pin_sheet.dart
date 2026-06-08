import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/tokens.dart';
import '../controllers/chat_controller.dart';
import 'haptic_touchable.dart';

enum PinSheetMode {
  setup,
  confirm,
  unlock,
  verifyCurrent,
  createNew,
  confirmNew,
}

class PinSheet extends StatefulWidget {
  final PinSheetMode mode;
  final String? expectedPin; // Used for confirmation / verification
  final Function(String pin) onSuccess;

  const PinSheet({
    super.key,
    required this.mode,
    this.expectedPin,
    required this.onSuccess,
  });

  static void show({
    required BuildContext context,
    required PinSheetMode mode,
    String? expectedPin,
    required Function(String pin) onSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PinSheet(
          mode: mode,
          expectedPin: expectedPin,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet> with SingleTickerProviderStateMixin {
  String _enteredCode = '';
  late PinSheetMode _currentMode;
  String? _firstEnteredPin; // Temp store during setup confirmation
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _firstEnteredPin = widget.expectedPin;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredCode.length >= 4) return;

    setState(() {
      _enteredCode += digit;
      _isError = false;
    });

    if (_enteredCode.length == 4) {
      // Process full PIN entry
      Future.delayed(const Duration(milliseconds: 150), _verifyPin);
    }
  }

  void _onBackspacePressed() {
    if (_enteredCode.isEmpty) return;
    setState(() {
      _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
      _isError = false;
    });
  }

  void _triggerWarningFeedback() {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0.0);
    setState(() {
      _enteredCode = '';
      _isError = true;
    });
  }

  Future<void> _verifyPin() async {
    switch (_currentMode) {
      case PinSheetMode.setup:
        // Transition to confirm mode
        setState(() {
          _firstEnteredPin = _enteredCode;
          _enteredCode = '';
          _currentMode = PinSheetMode.confirm;
        });
        break;

      case PinSheetMode.confirm:
        if (_enteredCode == _firstEnteredPin) {
          Navigator.pop(context);
          widget.onSuccess(_enteredCode);
        } else {
          _triggerWarningFeedback();
        }
        break;

      case PinSheetMode.unlock:
        if (widget.expectedPin != null) {
          if (_enteredCode == widget.expectedPin) {
            Navigator.pop(context);
            widget.onSuccess(_enteredCode);
          } else {
            _triggerWarningFeedback();
          }
        } else {
          final success = await ChatController().unlockVault(_enteredCode);
          if (!mounted) return;
          if (success) {
            Navigator.pop(context);
            widget.onSuccess(_enteredCode);
          } else {
            _triggerWarningFeedback();
          }
        }
        break;

      case PinSheetMode.verifyCurrent:
        if (_enteredCode == widget.expectedPin) {
          Navigator.pop(context);
          widget.onSuccess(_enteredCode);
        } else {
          _triggerWarningFeedback();
        }
        break;

      case PinSheetMode.createNew:
        setState(() {
          _firstEnteredPin = _enteredCode;
          _enteredCode = '';
          _currentMode = PinSheetMode.confirmNew;
        });
        break;

      case PinSheetMode.confirmNew:
        if (_enteredCode == _firstEnteredPin) {
          Navigator.pop(context);
          widget.onSuccess(_enteredCode);
        } else {
          _triggerWarningFeedback();
        }
        break;
    }
  }

  String _getInstructionText() {
    switch (_currentMode) {
      case PinSheetMode.setup:
        return 'Create 4-Digit Access PIN';
      case PinSheetMode.confirm:
        return 'Confirm Access PIN';
      case PinSheetMode.unlock:
        return 'Enter PIN to Unlock Notes';
      case PinSheetMode.verifyCurrent:
        return 'Enter Current active PIN';
      case PinSheetMode.createNew:
        return 'Enter New 4-Digit PIN';
      case PinSheetMode.confirmNew:
        return 'Confirm New Access PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SafeTalkTheme.cardBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1C6C82C5),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: SafeTalkTheme.borderSage,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Padlock Icon
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: SafeTalkTheme.brandSage,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'ENCRYPTED JOURNAL VAULT',
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary)
                .copyWith(fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _getInstructionText(),
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Progress Dots Indicators
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value * math.sin(_shakeController.value * 6 * math.pi), 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredCode.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isError
                            ? SafeTalkTheme.brandGold
                            : (isFilled ? SafeTalkTheme.brandTerracotta : Colors.transparent),
                        border: Border.all(
                          color: _isError
                              ? SafeTalkTheme.brandGold
                              : SafeTalkTheme.brandTerracotta,
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Digits Keyboard Grid
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['1', '2', '3'].map(_buildKeypadButton).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['4', '5', '6'].map(_buildKeypadButton).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['7', '8', '9'].map(_buildKeypadButton).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBackTextButton(),
                    _buildKeypadButton('0'),
                    _buildBackspaceIconButton(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return HapticTouchable(
      onTap: () => _onDigitPressed(digit),
      pressedScale: 0.90,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: SafeTalkTheme.bgMidnight,
          shape: BoxShape.circle,
          border: Border.all(color: SafeTalkTheme.borderSage, width: 1),
        ),
        child: Center(
          child: Text(
            digit,
            style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary)
                .copyWith(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildBackTextButton() {
    return SizedBox(
      height: 64,
      width: 64,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBackspaceIconButton() {
    return HapticTouchable(
      onTap: _onBackspacePressed,
      pressedScale: 0.90,
      child: SizedBox(
        height: 64,
        width: 64,
        child: Icon(
          Icons.backspace_outlined,
          color: SafeTalkTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
