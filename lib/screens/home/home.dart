import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fireb/models/user.dart';
import 'package:fireb/models/word.dart';
import 'package:fireb/screens/services/history_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../menu_screen.dart';
import '../translate_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.tightFor(),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeScreen(key: ValueKey(widget.key), initialShowAllHistory: false),
      const TranslateScreen(),
      const MenuScreen(),
    ];

    final theme = Theme.of(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: theme.cardColor,
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate_rounded),
              activeIcon: Icon(Icons.translate_rounded),
              label: 'Translate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Menu',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  final bool initialShowAllHistory;

  const _HomeScreen({super.key, this.initialShowAllHistory = false});

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> with AutomaticKeepAliveClientMixin {
  Word? _wordOfTheDay;
  late FlutterTts _flutterTts;
  late bool _showAllHistory;
  final int _historyDisplayLimit = 4;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _showAllHistory = widget.initialShowAllHistory;
    _initializeTts();
    _loadWordOfTheDay();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
  }

  Future<void> _loadWordOfTheDay() async {
    try {
      final String response = await rootBundle.loadString('assets/dictionary.json');
      final List<dynamic> data = json.decode(response);
      if (data.isNotEmpty) {
        final randomWord = data[Random().nextInt(data.length)];
        setState(() {
          _wordOfTheDay = Word.fromJson(randomWord);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _speak(Word word) async {
    Provider.of<HistoryService>(context, listen: false).addWordToHistory(word);
    await _flutterTts.speak(word.higaonon);
  }

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/sagiri.jpg');
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    } else {
      return FileImage(File(avatarUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userData = Provider.of<UserData?>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              centerTitle: false,
              title: Text(
                'Hi, ${userData?.name ?? 'User'}!',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(color: theme.scaffoldBackgroundColor),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: _getAvatarImage(userData?.avatarUrl),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWordOfTheDayCard(theme),
                  const SizedBox(height: 24),
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),
                  _buildHistorySection(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordOfTheDayCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.redAccent, Colors.orangeAccent.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _wordOfTheDay == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WORD OF THE DAY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _wordOfTheDay!.higaonon,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
                        onPressed: () => _speak(_wordOfTheDay!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _wordOfTheDay!.english,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _wordOfTheDay!.partOfSpeech,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Learning',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(
              theme,
              'Daily Quiz',
              Icons.quiz_rounded,
              Colors.blueAccent,
              () {},
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              theme,
              'Practice',
              Icons.record_voice_over_rounded,
              Colors.greenAccent.shade700,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    return Consumer<HistoryService>(
      builder: (context, historyService, child) {
        final showToggle = historyService.history.length > _historyDisplayLimit;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                if (showToggle)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllHistory = !_showAllHistory;
                      });
                    },
                    child: Text(
                      _showAllHistory ? 'Show Less' : 'Show All',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (historyService.history.isEmpty)
              _buildEmptyHistory(theme)
            else
              _buildHistoryListView(historyService, theme),
          ],
        );
      },
    );
  }

  Widget _buildEmptyHistory(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: theme.disabledColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: TextStyle(color: theme.disabledColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListView(HistoryService historyService, ThemeData theme) {
    final int effectiveItemCount = _showAllHistory
        ? historyService.history.length
        : min(_historyDisplayLimit, historyService.history.length);

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: effectiveItemCount,
      itemBuilder: (context, index) {
        final word = historyService.history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              word.higaonon,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(word.english),
            trailing: CircleAvatar(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 18, color: Colors.redAccent),
                onPressed: () => _speak(word),
              ),
            ),
          ),
        );
      },
    );
  }
}
