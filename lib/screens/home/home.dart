import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fireb/models/user.dart';
import 'package:fireb/models/word.dart';
import 'package:fireb/screens/services/auth.dart';
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Translate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserSection(userData, theme),
            const SizedBox(height: 30),
            _buildWordOfTheDaySection(theme),
            const SizedBox(height: 30),
            _buildHistorySection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(UserData? userData, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: _getAvatarImage(userData?.avatarUrl),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
            Text(
              userData?.name ?? 'User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWordOfTheDaySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word of the Day',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _wordOfTheDay == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _wordOfTheDay!.higaonon,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                          ),
                          IconButton(
                            icon: Icon(Icons.volume_up, color: theme.colorScheme.secondary, size: 30),
                            onPressed: () => _speak(_wordOfTheDay!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _wordOfTheDay!.english,
                        style: TextStyle(fontSize: 18, color: theme.textTheme.bodyMedium?.color),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: Icon(Icons.bookmark_border, color: theme.textTheme.bodySmall?.color, size: 28),
                          onPressed: () {
                            // TODO: Implement bookmark functionality
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryListView(HistoryService historyService) {
    final int effectiveItemCount = _showAllHistory
        ? historyService.history.length
        : min(_historyDisplayLimit, historyService.history.length);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: effectiveItemCount,
      itemBuilder: (context, index) {
        final word = historyService.history[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(word.higaonon),
            subtitle: Text(word.english),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up, size: 22),
              onPressed: () => _speak(word),
            ),
          ),
        );
      },
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
                  'History',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodySmall?.color),
                ),
                if (showToggle)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllHistory = !_showAllHistory;
                      });
                    },
                    child: Text(_showAllHistory ? 'Show Less' : 'Show All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (historyService.history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Your browsing history will appear here.',
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              _buildHistoryListView(historyService),
          ],
        );
      },
    );
  }
}
