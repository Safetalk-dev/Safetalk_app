import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/theme/tokens.dart';
import 'package:app/models/user_model.dart';
import 'package:app/services/user_service.dart';
import 'package:app/constants/languages.dart';

class OnboardingScreen extends StatefulWidget {
  final User firebaseUser;

  const OnboardingScreen({super.key, required this.firebaseUser});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedRole = 'user';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _specialtiesController = TextEditingController();
  final List<String> _selectedLanguages = ['en'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.firebaseUser.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _specialtiesController.dispose();
    super.dispose();
  }

  void _toggleLanguage(String code) {
    setState(() {
      if (_selectedLanguages.contains(code)) {
        if (_selectedLanguages.length > 1) {
          _selectedLanguages.remove(code);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one language')),
          );
        }
      } else {
        _selectedLanguages.add(code);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one language')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isSeeker = _selectedRole == 'user';
    final specialtiesList = _specialtiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final newUser = UserModel(
      uid: widget.firebaseUser.uid,
      email: widget.firebaseUser.email ?? '',
      displayName: _nameController.text.trim(),
      role: _selectedRole,
      profileComplete: true,
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
              bio: _bioController.text.trim().isNotEmpty
                  ? _bioController.text.trim()
                  : 'Compassionate peer ready to listen.',
              specialties: specialtiesList.isNotEmpty
                  ? specialtiesList
                  : ['Active Listening', 'Emotional Support'],
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
    final isSeeker = _selectedRole == 'user';

    return Scaffold(
      backgroundColor: SafeTalkTheme.bgMidnight,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: SafeTalkTheme.bgMidnight,
        foregroundColor: SafeTalkTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to SafeTalk',
              style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to participate in the sanctuary.',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            
            // Role Selection
            Text(
              'I want to...',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    title: 'Seek Support',
                    subtitle: 'Anonymous listener sessions',
                    isSelected: isSeeker,
                    onTap: () => setState(() => _selectedRole = 'user'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoleCard(
                    title: 'Be a Listener',
                    subtitle: 'Support peers in need',
                    isSelected: !isSeeker,
                    onTap: () => setState(() => _selectedRole = 'listener'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Display Name
            Text(
              isSeeker ? 'Your Anonymous Moniker' : 'Your Listener Display Name',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
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
                hintText: isSeeker ? 'e.g. Calm Ocean' : 'e.g. Amber R.',
                hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Languages Spoken / Preferred
            Text(
              isSeeker ? 'Preferred Languages' : 'Languages You Speak (ISO 639-1)',
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kSupportedLanguages.map((lang) {
                final isSelected = _selectedLanguages.contains(lang.code);
                return FilterChip(
                  label: Text('${lang.name} (${lang.code})'),
                  selected: isSelected,
                  selectedColor: SafeTalkTheme.brandSage.withValues(alpha: 0.25),
                  backgroundColor: SafeTalkTheme.cardBg,
                  labelStyle: TextStyle(
                    color: isSelected ? SafeTalkTheme.brandSage : SafeTalkTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? SafeTalkTheme.brandSage : Colors.transparent,
                  ),
                  onSelected: (_) => _toggleLanguage(lang.code),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Listener-specific fields (Bio & Specialties)
            if (!isSeeker) ...[
              Text(
                'Listener Bio',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: SafeTalkTheme.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Share a gentle note about your listening approach...',
                  hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Specialties (comma-separated)',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _specialtiesController,
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: SafeTalkTheme.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'e.g. Anxiety, Loneliness, Grief, Work Stress',
                  hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 16),

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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? SafeTalkTheme.brandSage.withValues(alpha: 0.1) : SafeTalkTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SafeTalkTheme.brandSage : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: SafeTalkTheme.bodyStyle(
                color: isSelected ? SafeTalkTheme.brandSage : SafeTalkTheme.textPrimary,
                bold: isSelected,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? SafeTalkTheme.brandSage.withValues(alpha: 0.8) : SafeTalkTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
