import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'listener_detail_screen.dart';
import '../../widgets/haptic_touchable.dart';
import '../../controllers/session_controller.dart';

class UserExploreScreen extends StatefulWidget {
  final String username;
  final bool checkInCompleted;
  final Function(double score) onMoodCheckedIn;
  final Function(SessionType type) onRequestListener;
  final Function(String listenerName) onOpenListenerChat;
  final List<Map<String, dynamic>> allListeners;
  final List<String> regularListenerNames;
  final Function(String name) onToggleRegular;

  const UserExploreScreen({
    super.key,
    required this.username,
    required this.checkInCompleted,
    required this.onMoodCheckedIn,
    required this.onRequestListener,
    required this.onOpenListenerChat,
    required this.allListeners,
    required this.regularListenerNames,
    required this.onToggleRegular,
  });

  @override
  State<UserExploreScreen> createState() => _UserExploreScreenState();
}

class _UserExploreScreenState extends State<UserExploreScreen> {
  String selectedMood = 'All';
  final List<String> moodChips = ['All', 'Anxious', 'Lonely', 'Overwhelmed', 'Venting', 'Grief'];
  
  // Daily questionnaire rating scale state
  int _selectedCheckInScore = 7;

  // Search filter states
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _showSessionSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: SafeTalkTheme.cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SafeTalkTheme.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Start Support Session',
                style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Select your preferred connection medium. All sessions are secure, private, and encrypted.',
                style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildSessionOptionCard(
                context,
                type: SessionType.messages,
                title: 'Messages Session',
                duration: '10 min duration',
                price: '₹150 / session',
                icon: Icons.chat_bubble_outline_rounded,
                color: SafeTalkTheme.brandTerracotta,
              ),
              const SizedBox(height: 12),
              _buildSessionOptionCard(
                context,
                type: SessionType.voiceCall,
                title: 'Voice Call Session',
                duration: '10 min duration',
                price: '₹150 / session',
                icon: Icons.phone_outlined,
                color: SafeTalkTheme.brandSage,
              ),
              const SizedBox(height: 12),
              _buildSessionOptionCard(
                context,
                type: SessionType.videoCall,
                title: 'Video Call Session',
                duration: '7 min duration',
                price: '₹150 / session',
                icon: Icons.videocam_outlined,
                color: SafeTalkTheme.brandGold,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionOptionCard(
    BuildContext context, {
    required SessionType type,
    required String title,
    required String duration,
    required String price,
    required IconData icon,
    required Color color,
  }) {
    return HapticTouchable(
      onTap: () {
        Navigator.pop(context);
        widget.onRequestListener(type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
          border: Border.all(color: SafeTalkTheme.borderSage, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: SafeTalkTheme.bodyStyle(color: color, bold: true).copyWith(fontSize: 15),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: SafeTalkTheme.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchLower = _searchQuery.toLowerCase();
    final filteredListeners = widget.allListeners.where((l) {
      final matchesMood = selectedMood == 'All' || 
          (l['specialties'] as List<String>).contains(selectedMood);
      final matchesSearch = searchLower.isEmpty ||
          l['name'].toString().toLowerCase().contains(searchLower) ||
          (l['specialties'] as List<String>).any((s) => s.toLowerCase().contains(searchLower)) ||
          l['bio'].toString().toLowerCase().contains(searchLower);
      return matchesMood && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Header with editable Moniker!
          Text(
            'How is your heart today,',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.textPrimary).copyWith(fontSize: 24),
          ),
          Text(
            '${widget.username}?',
            style: SafeTalkTheme.displayStyle(color: SafeTalkTheme.brandTerracotta).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us how you feel, and we\'ll suggest matching ears.',
            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Glassmorphic Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: SafeTalkTheme.glassCardDecoration.copyWith(
              border: Border.all(
                color: _searchQuery.isNotEmpty 
                    ? SafeTalkTheme.brandTerracotta.withValues(alpha: 0.5) 
                    : SafeTalkTheme.borderSage,
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search companions by name, bio, or focus...',
                hintStyle: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                border: InputBorder.none,
                icon: const Icon(Icons.search_rounded, color: SafeTalkTheme.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: SafeTalkTheme.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // --- NEW: DAILY EMOTIONAL QUESTIONNAIRE ---
          _buildDailyCheckInCard(),

          const SizedBox(height: 28),

          // Mood Scroll List
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: moodChips.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final mood = moodChips[index];
                final isSelected = selectedMood == mood;
                return Padding(
                  key: ValueKey(mood),
                  padding: const EdgeInsets.only(right: 10.0),
                  child: HapticTouchable(
                    onTap: () {
                      setState(() {
                        selectedMood = mood;
                      });
                    },
                    child: ChoiceChip(
                      label: Text(
                        mood,
                        style: SafeTalkTheme.bodyStyle(
                          color: isSelected ? SafeTalkTheme.bgMidnight : SafeTalkTheme.textPrimary,
                          bold: isSelected,
                        ).copyWith(fontSize: 13),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedMood = mood;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      selectedColor: SafeTalkTheme.brandTerracotta,
                      backgroundColor: SafeTalkTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: SafeTalkTheme.pillRadius,
                        side: BorderSide(
                          color: isSelected ? SafeTalkTheme.brandTerracotta : SafeTalkTheme.borderSage,
                          width: 1,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // Match Instantly Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SafeTalkTheme.brandTerracotta, SafeTalkTheme.brandGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: SafeTalkTheme.organicCardRadius,
              boxShadow: SafeTalkTheme.glowShadow(SafeTalkTheme.brandTerracotta, opacity: 0.25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Matching',
                        style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.bgMidnight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect instantly with the next available companion specialized in handling acute anxiety.',
                        style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight.withValues(alpha: 0.8))
                            .copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                HapticTouchable(
                  onTap: () => _showSessionSelectionSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: SafeTalkTheme.bgForest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: SafeTalkTheme.brandTerracotta,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Active Listeners List Title
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Compassionate Neighbors',
                  style: SafeTalkTheme.headingStyle(color: SafeTalkTheme.textPrimary),
                ),
                const SizedBox(width: 16),
                Text(
                  '${filteredListeners.length} active',
                  style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Listener Cards
          if (filteredListeners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No listeners active in this mood category right now.',
                  style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredListeners.length,
              itemBuilder: (context, index) {
                final peer = filteredListeners[index];
                return Padding(
                  key: ValueKey(peer['name']),
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListenerDetailScreen(
                            listener: peer,
                            isRegular: widget.regularListenerNames.contains(peer['name']),
                            onToggleRegular: widget.onToggleRegular,
                            onMessage: () {
                              Navigator.pop(context);
                              widget.onOpenListenerChat(peer['name']);
                            },
                            onConnectNow: () {
                              Navigator.pop(context);
                              _showSessionSelectionSheet(context);
                            },
                            onBack: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: SafeTalkTheme.glassCardDecoration.copyWith(
                        border: Border.all(
                          color: peer['active']
                              ? SafeTalkTheme.brandSage.withValues(alpha: 0.3)
                              : SafeTalkTheme.borderSage,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: peer['active'] ? SafeTalkTheme.brandSage : SafeTalkTheme.textMuted,
                                  boxShadow: peer['active']
                                      ? SafeTalkTheme.glowShadow(SafeTalkTheme.brandSage, opacity: 0.6)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                peer['name'],
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true)
                                    .copyWith(fontSize: 16),
                              ),
                              const Spacer(),
                              const Icon(Icons.star, color: SafeTalkTheme.brandGold, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                peer['rating'],
                                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.brandGold, bold: true)
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: (peer['specialties'] as List<String>).map((spec) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: SafeTalkTheme.bgMidnight,
                                      borderRadius: SafeTalkTheme.pillRadius,
                                      border: Border.all(color: SafeTalkTheme.borderSage, width: 1),
                                    ),
                                    child: Text(
                                      spec,
                                      style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.brandSageLight),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            peer['bio'],
                            style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textSecondary)
                                .copyWith(fontSize: 13.5, height: 1.4),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ListenerDetailScreen(
                                          listener: peer,
                                          isRegular: widget.regularListenerNames.contains(peer['name']),
                                          onToggleRegular: widget.onToggleRegular,
                                          onMessage: () {
                                            Navigator.pop(context);
                                            widget.onOpenListenerChat(peer['name']);
                                          },
                                          onConnectNow: () {
                                            Navigator.pop(context);
                                            _showSessionSelectionSheet(context);
                                          },
                                          onBack: () => Navigator.pop(context),
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: SafeTalkTheme.textPrimary,
                                    side: const BorderSide(color: SafeTalkTheme.borderSage, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: SafeTalkTheme.standardRadius,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'View Profile',
                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showSessionSelectionSheet(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SafeTalkTheme.brandSage,
                                    foregroundColor: SafeTalkTheme.bgMidnight,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: SafeTalkTheme.organicCardRadius,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 4,
                                    shadowColor: SafeTalkTheme.brandSage.withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    'Connect Now',
                                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  // --- COMPILER FOR DAILY EMOTIONAL CHECK-IN CARD ---
  Widget _buildDailyCheckInCard() {
    if (widget.checkInCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: SafeTalkTheme.glassCardDecoration.copyWith(
          border: Border.all(color: SafeTalkTheme.brandSage.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: SafeTalkTheme.brandSage.withValues(alpha: 0.12),
              child: const Icon(Icons.check, color: SafeTalkTheme.brandSage, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emotional Balance Logged',
                    style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your weekly rolling tracker in your Profile has been successfully updated. Take a slow deep breath.',
                    style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: SafeTalkTheme.glassCardDecoration.copyWith(
        border: Border.all(color: SafeTalkTheme.brandTerracotta.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header titles
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: SafeTalkTheme.brandTerracotta, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Emotional Check-in',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.textPrimary, bold: true).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rate your inner balance today (1 to 10) to update your rolling tracker curve:',
            style: SafeTalkTheme.captionStyle(color: SafeTalkTheme.textSecondary),
          ),
          
          const SizedBox(height: 18),

          // 1 to 10 therapeutic horizontal grid selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(10, (index) {
                final score = index + 1;
                final isSelected = _selectedCheckInScore == score;
                
                // Color spectrum (Terracotta coral for low, Sage green for high)
                final Color scoreColor = Color.lerp(
                  SafeTalkTheme.brandTerracotta, 
                  SafeTalkTheme.brandSage, 
                  index / 9.0
                ) ?? SafeTalkTheme.brandSage;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCheckInScore = score;
                      });
                    },
                    borderRadius: SafeTalkTheme.pillRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? scoreColor : SafeTalkTheme.bgMidnight,
                        border: Border.all(
                          color: isSelected ? Colors.transparent : SafeTalkTheme.borderSage,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: SafeTalkTheme.bodyStyle(
                            color: isSelected ? SafeTalkTheme.bgMidnight : SafeTalkTheme.textPrimary,
                            bold: true,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Log button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => widget.onMoodCheckedIn(_selectedCheckInScore.toDouble()),
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeTalkTheme.brandTerracotta,
                foregroundColor: SafeTalkTheme.bgMidnight,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: SafeTalkTheme.organicCardRadius),
              ),
              child: Text(
                'Log Emotional Balance',
                style: SafeTalkTheme.bodyStyle(color: SafeTalkTheme.bgMidnight, bold: true).copyWith(fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
