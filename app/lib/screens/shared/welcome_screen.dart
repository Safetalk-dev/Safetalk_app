import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/safetalk_logo.dart';

class WelcomeScreen extends StatelessWidget {
  final Function(String selectedRole) onRoleSelected;

  const WelcomeScreen({super.key, required this.onRoleSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: SafeTalkTheme.ambientBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Stylized modern Safe Talk S-logo
                const SafeTalkLogo(
                  size: 180,
                  animate: true,
                ),
                
                const Spacer(flex: 2),
                
                // Elegant branding
                Text(
                  'safe talk',
                  style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(
                    fontSize: 40,
                    letterSpacing: -1.5,
                    fontWeight: FontWeight.w300, // Minimalist ultra-premium lowercase design
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A quiet harbor for peer support and silent validation.',
                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 3),
                
                // Role Buttons Stack
                Column(
                  children: [
                    // Seeker: "I need to share"
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => onRoleSelected('user'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SafeTalkTheme.brandTerracotta,
                          foregroundColor: SafeTalkTheme.bgMidnight,
                          elevation: 6,
                          shadowColor: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: SafeTalkTheme.organicCardRadius,
                          ),
                        ),
                        child: Text(
                          'I need to share',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true)
                              .copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Listener: "I am here to listen"
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => onRoleSelected('listener'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SafeTalkTheme.brandSageLight,
                          side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: SafeTalkTheme.organicCardRadius,
                          ),
                        ),
                        child: Text(
                          'I am here to listen',
                          style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandSageLight, bold: true)
                              .copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // End-to-end security badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: SafeTalkTheme.brandSageLight.withValues(alpha: 0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Double Encrypted • Completely Anonymous',
                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary).copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
