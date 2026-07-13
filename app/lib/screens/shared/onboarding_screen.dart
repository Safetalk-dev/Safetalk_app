import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/theme/tokens.dart';
import 'package:app/models/user_model.dart';
import 'package:app/services/user_service.dart';

class OnboardingScreen extends StatefulWidget {
  final User firebaseUser;

  const OnboardingScreen({super.key, required this.firebaseUser});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedRole = 'user';
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedLanguages = ['en'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.firebaseUser.displayName ?? '';
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isSeeker = _selectedRole == 'user';

    final newUser = UserModel(
      uid: widget.firebaseUser.uid,
      email: widget.firebaseUser.email ?? '',
      displayName: _nameController.text.trim(),
      role: _selectedRole,
      seekerData: isSeeker
          ? SeekerData(
              walletBalance: 0.0,
              preferredLanguages: _selectedLanguages,
              safeCircle: [],
            )
          : null,
      listenerData: !isSeeker
          ? ListenerData(
              isOnline: false,
              status: 'offline',
              languagesSpoken: _selectedLanguages,
              stats: ListenerStats(rating: 5.0, minutesListened: 0),
            )
          : null,
    );

    try {
      await UserService().createUser(newUser);
      // The StreamBuilder in AuthWrapper will automatically reconstruct
      // and fetch the newly created UserModel, routing to the correct layout.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeTalkTheme.bgMidnight,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: SafeTalkTheme.bgMidnight,
        foregroundColor: SafeTalkTheme.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to SafeTalk',
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Role Selection
            Text(
              'I want to...',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    title: 'Seek Support',
                    isSelected: _selectedRole == 'user',
                    onTap: () => setState(() => _selectedRole = 'user'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoleCard(
                    title: 'Be a Listener',
                    isSelected: _selectedRole == 'listener',
                    onTap: () => setState(() => _selectedRole = 'listener'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Display Name
            Text(
              _selectedRole == 'user' ? 'Your Anonymous Moniker' : 'Your Display Name',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: SafeTalkTheme.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'e.g. Calm Ocean',
                hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 48),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: SafeTalkTheme.brandSage))
                : ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeTalkTheme.brandSage,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Complete Profile',
                      style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? SafeTalkTheme.brandSage.withValues(alpha: 0.1) : SafeTalkTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SafeTalkTheme.brandSage : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: SafeTalkTheme.bodyStyle(
            color: isSelected ? SafeTalkTheme.brandSage : SafeTalkTheme.textSecondary,
            bold: isSelected,
          ),
        ),
      ),
    );
  }
}
