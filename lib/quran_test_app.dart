import 'package:flutter/material.dart';

import 'quran/models/quran_ayah.dart';
import 'quran/quran_database.dart';

/// Minimal reader that pairs Indopak Nastaleeq with the ayah SQLite edition.
///
/// Follows [fonts.quran.ws Recipe 1](https://fonts.quran.ws/usage): Unicode text
/// fonts render ayah text directly — set RTL direction, Nastaleeq family, and
/// generous line height (~2.3× font size).
class QuranTestApp extends StatelessWidget {
  const QuranTestApp({super.key});

  static const _fontFamily = 'IndopakNastaleeq';

  /// Matches the web guide: `font-size: 2rem; line-height: 2.3`.
  static const _quranTextStyle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    height: 2.3,
    color: Color(0xFF1A1A1A),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quran Font Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D3D2E)),
        useMaterial3: true,
      ),
      home: const _QuranTestHome(),
    );
  }
}

class _QuranTestHome extends StatefulWidget {
  const _QuranTestHome();

  @override
  State<_QuranTestHome> createState() => _QuranTestHomeState();
}

class _QuranTestHomeState extends State<_QuranTestHome> {
  static const _surahAyahCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30,
    20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4,
    5, 6,
  ];

  int _selectedSurah = 1;
  int? _ayahCount;
  List<QuranAyah> _ayat = const [];
  String? _error;
  bool _loading = true;
  final _scrollController = ScrollController();
  final _ayahKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _loadSurah(_selectedSurah);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSurah(int surah, {int? scrollToAyah}) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedSurah = surah;
      _ayahKeys.clear();
    });

    try {
      final db = QuranDatabase.instance;
      final count = await db.ayahCount();
      final ayat = await db.ayatForSurah(surah);
      if (!mounted) {
        return;
      }
      setState(() {
        _ayahCount = count;
        _ayat = ayat;
        _loading = false;
      });
      if (scrollToAyah != null) {
        _scrollToAyah(scrollToAyah);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _scrollToAyah(int ayahNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _ayahKeys[ayahNumber];
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  GlobalKey _keyForAyah(int ayahNumber) {
    return _ayahKeys.putIfAbsent(ayahNumber, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indopak Nastaleeq Test'),
        actions: [
          if (_ayahCount != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_ayahCount ayat',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Surah',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedSurah,
                        items: List.generate(114, (index) {
                          final surah = index + 1;
                          return DropdownMenuItem(
                            value: surah,
                            child: Text(
                              'Surah $surah (${_surahAyahCounts[index]} ayat)',
                            ),
                          );
                        }),
                        onChanged: _loading
                            ? null
                            : (value) {
                                if (value != null) {
                                  _loadSurah(value);
                                }
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: _loading
                      ? null
                      : () => _loadSurah(2, scrollToAyah: 255),
                  child: const Text('2:255'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Unicode Nastaleeq font + indopak-nastaleeq-ayah SQLite. '
              'Text renders directly (Recipe 1 on fonts.quran.ws).',
              style: TextStyle(fontSize: 13, color: Color(0xFF5C5C5C)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to open quran.sqlite:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_ayat.isEmpty) {
      return const Center(child: Text('No ayat found for this surah.'));
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _ayat.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final ayah = _ayat[index];
        return _AyahTile(
          key: _keyForAyah(ayah.ayah),
          ayah: ayah,
        );
      },
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({super.key, required this.ayah});

  final QuranAyah ayah;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (ayah.page case final page?) 'Page $page',
      if (ayah.juz case final juz?) 'Juz $juz',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${ayah.ayah}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${ayah.surah}:${ayah.ayah}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                meta,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            ayah.text,
            textAlign: TextAlign.right,
            style: QuranTestApp._quranTextStyle,
          ),
        ),
      ],
    );
  }
}
