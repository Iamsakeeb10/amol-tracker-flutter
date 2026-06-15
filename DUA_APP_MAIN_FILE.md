import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
void main() async {
WidgetsFlutterBinding.ensureInitialized();
// Load favorites before the app renders
await FavoritesStore().init();
runApp(const DuaApp());
}

// ─────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────
class AppTheme {
static const Color primary = Color(0xFF1B6B5A);
static const Color primaryLight = Color(0xFF2D9374);
static const Color primaryDark = Color(0xFF0F4A3E);
static const Color accent = Color(0xFFD4A843);
static const Color accentLight = Color(0xFFF0C96A);
static const Color background = Color(0xFFF7F3EE);
static const Color surface = Color(0xFFFFFFFF);
static const Color arabicBg = Color(0xFFF0EAD6);
static const Color textPrimary = Color(0xFF1A2C2A);
static const Color textSecondary = Color(0xFF5A7068);
static const Color divider = Color(0xFFE0D8C8);
static const Color error = Color(0xFFB04040);

static ThemeData get theme => ThemeData(
colorScheme: ColorScheme.fromSeed(
seedColor: primary,
primary: primary,
secondary: accent,
surface: surface,
error: error,
),
scaffoldBackgroundColor: background,
appBarTheme: const AppBarTheme(
backgroundColor: primary,
foregroundColor: Colors.white,
elevation: 0,
centerTitle: true,
titleTextStyle: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w600,
color: Colors.white,
),
),
bottomNavigationBarTheme: const BottomNavigationBarThemeData(
backgroundColor: surface,
selectedItemColor: primary,
unselectedItemColor: Color(0xFF9EB5AE),
type: BottomNavigationBarType.fixed,
elevation: 12,
),
cardTheme: CardThemeData(
color: surface,
elevation: 2,
shadowColor: primary.withOpacity(0.1),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
),
useMaterial3: true,
);
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class DuaCategory {
final String name;
final String url;
final String meta;

DuaCategory({required this.name, required this.url, required this.meta});

factory DuaCategory.fromJson(Map<String, dynamic> j) => DuaCategory(
name: j['name'] ?? '',
url: j['url'] ?? '',
meta: j['meta'] ?? '',
);
}

class DuaSubCategory {
final int id;
final String title;
final String category;
final List<int> duaIds;

DuaSubCategory({
required this.id,
required this.title,
required this.category,
required this.duaIds,
});

factory DuaSubCategory.fromJson(Map<String, dynamic> j) => DuaSubCategory(
id: j['id'] ?? 0,
title: j['title'] ?? '',
category: j['category'] ?? '',
duaIds: List<int>.from(j['dua-ids'] ?? []),
);
}

class DuaHadith {
final String title;
final String arabic;
final String translation;

DuaHadith({
required this.title,
required this.arabic,
required this.translation,
});

factory DuaHadith.fromJson(Map<String, dynamic> j) => DuaHadith(
title: j['title'] ?? '',
arabic: j['arabic'] ?? '',
translation: j['translation'] ?? '',
);
}

class DuaBenefits {
final String title;
final String description;
final List<String> points;

DuaBenefits({
required this.title,
required this.description,
required this.points,
});

factory DuaBenefits.fromJson(Map<String, dynamic> j) => DuaBenefits(
title: j['title'] ?? '',
description: j['description'] ?? '',
points: List<String>.from(j['points'] ?? []),
);
}

class Dua {
final int duaId;
final String title;
final String introduction;
final String arabic;
final String audio;
final String transliteration;
final String translation;
final String reference;
final DuaHadith? hadith;
final DuaBenefits? benefits;

Dua({
required this.duaId,
required this.title,
required this.introduction,
required this.arabic,
required this.audio,
required this.transliteration,
required this.translation,
required this.reference,
this.hadith,
this.benefits,
});

factory Dua.fromJson(Map<String, dynamic> j) => Dua(
duaId: j['dua_id'] ?? 0,
title: j['title'] ?? '',
introduction: j['introduction'] ?? '',
arabic: j['arabic'] ?? '',
audio: j['audio'] ?? '',
transliteration: j['transliteration'] ?? '',
translation: j['translation'] ?? '',
reference: j['reference'] ?? '',
hadith: j['hadith'] is Map ? DuaHadith.fromJson(j['hadith']) : null,
benefits: j['benefits'] is Map ? DuaBenefits.fromJson(j['benefits']) : null,
);
}

// ─────────────────────────────────────────────
// ASSET DATA SERVICE (loads JSON once, caches in memory)
// ─────────────────────────────────────────────
class AssetDataService {
static final AssetDataService _i = AssetDataService._();
factory AssetDataService() => _i;
AssetDataService._();

List<DuaCategory>? \_categories;
List<DuaSubCategory>? \_subCategories;
List<Dua>? \_duas;

Future<List<DuaCategory>> getCategories() async {
\_categories ??= await \_loadCategories();
return \_categories!;
}

Future<List<DuaSubCategory>> getSubCategories() async {
\_subCategories ??= await \_loadSubCategories();
return \_subCategories!;
}

Future<List<Dua>> getAllDuas() async {
\_duas ??= await \_loadDuas();
return \_duas!;
}

Future<Dua> getDuaById(int id) async {
final all = await getAllDuas();
return all.firstWhere((d) => d.duaId == id);
}

Future<Dua> getRandomDua() async {
final all = await getAllDuas();
all.shuffle();
return all.first;
}

// ── Private loaders ───────────────────────────────────────────────────────

Future<List<DuaCategory>> \_loadCategories() async {
final raw = await rootBundle.loadString('assets/categories.json');
final list = jsonDecode(raw) as List;
final categories = list.map((e) => DuaCategory.fromJson(e)).toList();

    // ── DEBUG ─────────────────────────────────────────────────────────────
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║              CATEGORIES (assets/categories.json)        ║');
    debugPrint('╚══════════════════════════════════════════════════════════╝');
    debugPrint('Total count : ${categories.length}');
    debugPrint('');
    debugPrint('── Raw JSON shape of item[0] ──');
    debugPrint(const JsonEncoder.withIndent('  ').convert(list.first));
    debugPrint('');
    debugPrint('── Parsed Dart object shape ──');
    debugPrint('DuaCategory {');
    debugPrint('  name : "${categories.first.name}"');
    debugPrint('  url  : "${categories.first.url}"');
    debugPrint('  meta : "${categories.first.meta}"');
    debugPrint('}');
    debugPrint('');
    debugPrint('── All category names ──');
    for (int i = 0; i < categories.length; i++) {
      debugPrint('  [$i] ${categories[i].name}  (url: ${categories[i].url})');
    }
    // ─────────────────────────────────────────────────────────────────────

    return categories;

}

Future<List<DuaSubCategory>> \_loadSubCategories() async {
final raw = await rootBundle.loadString('assets/sub_categories.json');
final list = jsonDecode(raw) as List;
final subs = list.map((e) => DuaSubCategory.fromJson(e)).toList();

    // ── DEBUG ─────────────────────────────────────────────────────────────
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║        SUB-CATEGORIES (assets/sub_categories.json)      ║');
    debugPrint('╚══════════════════════════════════════════════════════════╝');
    debugPrint('Total count : ${subs.length}');
    debugPrint('');
    debugPrint('── Raw JSON shape of item[0] ──');
    debugPrint(const JsonEncoder.withIndent('  ').convert(list.first));
    debugPrint('');
    debugPrint('── Parsed Dart object shape ──');
    debugPrint('DuaSubCategory {');
    debugPrint('  id       : ${subs.first.id}');
    debugPrint('  title    : "${subs.first.title}"');
    debugPrint('  category : "${subs.first.category}"');
    debugPrint('  duaIds   : ${subs.first.duaIds}');
    debugPrint('}');
    debugPrint('');
    debugPrint('── First 10 sub-categories ──');
    for (int i = 0; i < subs.length && i < 10; i++) {
      debugPrint('  [${subs[i].id}] "${subs[i].title}"');
      debugPrint('       category → ${subs[i].category}');
      debugPrint('       dua ids  → ${subs[i].duaIds}');
    }
    // ─────────────────────────────────────────────────────────────────────

    return subs;

}

Future<List<Dua>> \_loadDuas() async {
final raw = await rootBundle.loadString('assets/duas.json');
final list = jsonDecode(raw) as List;
final duas = list.map((e) => Dua.fromJson(e)).toList();

    // ── DEBUG ─────────────────────────────────────────────────────────────
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════╗');
    debugPrint('║                  DUAS (assets/duas.json)                ║');
    debugPrint('╚══════════════════════════════════════════════════════════╝');
    debugPrint('Total count : ${duas.length}');
    debugPrint('');
    debugPrint('── Raw JSON shape of duas[0] (full) ──');
    debugPrint(const JsonEncoder.withIndent('  ').convert(list.first));
    debugPrint('');
    debugPrint('── Parsed Dart object shape ──');
    final d = duas.first;
    debugPrint('Dua {');
    debugPrint('  duaId           : ${d.duaId}');
    debugPrint('  title           : "${d.title}"');
    debugPrint('  introduction    : "${d.introduction}"');
    debugPrint('  arabic          : "${d.arabic}"');
    debugPrint('  audio           : "${d.audio}"');
    debugPrint('  transliteration : "${d.transliteration}"');
    debugPrint('  translation     : "${d.translation}"');
    debugPrint('  reference       : "${d.reference}"');
    debugPrint('  hadith          : ${d.hadith == null ? 'null' : '{'}');
    if (d.hadith != null) {
      debugPrint('    title       : "${d.hadith!.title}"');
      debugPrint('    arabic      : "${d.hadith!.arabic}"');
      debugPrint('    translation : "${d.hadith!.translation}"');
      debugPrint('  }');
    }
    debugPrint('  benefits        : ${d.benefits == null ? 'null' : '{'}');
    if (d.benefits != null) {
      debugPrint('    title       : "${d.benefits!.title}"');
      debugPrint('    description : "${d.benefits!.description}"');
      debugPrint('    points      : [');
      for (final p in d.benefits!.points) {
        debugPrint('      "$p"');
      }
      debugPrint('    ]');
      debugPrint('  }');
    }
    debugPrint('}');
    debugPrint('');
    debugPrint('── Null field audit (all duas) ──');
    final missingArabic = duas.where((d) => d.arabic.isEmpty).length;
    final missingTranslation = duas.where((d) => d.translation.isEmpty).length;
    final missingTransliteration = duas
        .where((d) => d.transliteration.isEmpty)
        .length;
    final missingReference = duas.where((d) => d.reference.isEmpty).length;
    final missingHadith = duas.where((d) => d.hadith == null).length;
    final missingBenefits = duas.where((d) => d.benefits == null).length;
    final missingIntro = duas.where((d) => d.introduction.isEmpty).length;
    debugPrint('  arabic missing          : $missingArabic / ${duas.length}');
    debugPrint(
      '  translation missing     : $missingTranslation / ${duas.length}',
    );
    debugPrint(
      '  transliteration missing : $missingTransliteration / ${duas.length}',
    );
    debugPrint(
      '  reference missing       : $missingReference / ${duas.length}',
    );
    debugPrint('  introduction missing    : $missingIntro / ${duas.length}');
    debugPrint('  hadith null             : $missingHadith / ${duas.length}');
    debugPrint('  benefits null           : $missingBenefits / ${duas.length}');
    debugPrint('');
    debugPrint('── First 5 duas (summary) ──');
    for (int i = 0; i < duas.length && i < 5; i++) {
      final dua = duas[i];
      debugPrint('  [${dua.duaId}] "${dua.title}"');
      debugPrint(
        '       reference : ${dua.reference.isEmpty ? "(none)" : dua.reference}',
      );
      debugPrint(
        '       hadith    : ${dua.hadith != null ? "✓" : "✗"}  benefits: ${dua.benefits != null ? "✓" : "✗"}',
      );
    }
    debugPrint('');
    // ─────────────────────────────────────────────────────────────────────

    return duas;

}
}

// ─────────────────────────────────────────────
// FAVORITES STORE (persisted via shared*preferences)
// ─────────────────────────────────────────────
class FavoritesStore extends ChangeNotifier {
static final FavoritesStore \_i = FavoritesStore.*();
factory FavoritesStore() => _i;
FavoritesStore._();

static const \_prefsKey = 'favorite_dua_ids';
final Set<int> \_ids = {};

Future<void> init() async {
final prefs = await SharedPreferences.getInstance();
final saved = prefs.getStringList(\_prefsKey) ?? [];
\_ids.addAll(saved.map(int.parse));
}

bool isFav(int id) => \_ids.contains(id);

Future<void> toggle(int id) async {
\_ids.contains(id) ? \_ids.remove(id) : \_ids.add(id);
notifyListeners();
final prefs = await SharedPreferences.getInstance();
await prefs.setStringList(\_prefsKey, \_ids.map((e) => '$e').toList());
}

Set<int> get all => Set.unmodifiable(\_ids);
}

// ─────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────
class DuaApp extends StatelessWidget {
const DuaApp({super.key});

@override
Widget build(BuildContext context) => MaterialApp(
title: 'দোয়া সংকলন',
theme: AppTheme.theme,
debugShowCheckedModeBanner: false,
home: const \_AppLoader(),
);
}

/// Warm-up: load all assets in parallel before showing UI
class \_AppLoader extends StatefulWidget {
const \_AppLoader();

@override
State<\_AppLoader> createState() => \_AppLoaderState();
}

class \_AppLoaderState extends State<\_AppLoader> {
@override
void initState() {
super.initState();
\_warmUp();
}

Future<void> _warmUp() async {
// Load all three assets in parallel — Flutter caches them after first read
await Future.wait([
AssetDataService().getCategories(),
AssetDataService().getSubCategories(),
AssetDataService().getAllDuas(),
]);
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const MainShell()),
);
}
}

@override
Widget build(BuildContext context) => Scaffold(
backgroundColor: AppTheme.primaryDark,
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text(
'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ',
style: TextStyle(
fontFamily: 'serif',
fontSize: 22,
color: AppTheme.accentLight,
height: 2,
),
),
const SizedBox(height: 24),
const Text(
'দোয়া সংকলন',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
const SizedBox(height: 48),
const SizedBox(
width: 32,
height: 32,
child: CircularProgressIndicator(
color: AppTheme.accent,
strokeWidth: 2.5,
),
),
const SizedBox(height: 16),
Text(
'লোড হচ্ছে...',
style: TextStyle(
color: Colors.white.withOpacity(0.6),
fontSize: 14,
),
),
],
),
),
);
}

// ─────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
const MainShell({super.key});

@override
State<MainShell> createState() => \_MainShellState();
}

class \_MainShellState extends State<MainShell> {
int \_tab = 0;

final List<Widget> \_pages = const [
HomePage(),
CategoryListPage(),
SearchPage(),
FavoritesPage(),
];

@override
Widget build(BuildContext context) => Scaffold(
body: IndexedStack(index: \_tab, children: \_pages),
bottomNavigationBar: BottomNavigationBar(
currentIndex: \_tab,
onTap: (i) => setState(() => \_tab = i),
items: const [
BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'হোম'),
BottomNavigationBarItem(
icon: Icon(Icons.category_rounded),
label: 'বিভাগ',
),
BottomNavigationBarItem(
icon: Icon(Icons.search_rounded),
label: 'খোঁজুন',
),
BottomNavigationBarItem(
icon: Icon(Icons.favorite_rounded),
label: 'পছন্দ',
),
],
),
);
}

// ─────────────────────────────────────────────
// HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => \_HomePageState();
}

class \_HomePageState extends State<HomePage> {
Dua? \_randomDua;

@override
void initState() {
super.initState();
\_nextRandom();
}

Future<void> \_nextRandom() async {
final dua = await AssetDataService().getRandomDua();
if (mounted) setState(() => \_randomDua = dua);
}

@override
Widget build(BuildContext context) => Scaffold(
body: CustomScrollView(
slivers: [
SliverAppBar(
expandedHeight: 200,
pinned: true,
backgroundColor: AppTheme.primary,
flexibleSpace: FlexibleSpaceBar(background: \_HeaderBanner()),
title: const Text('দোয়া সংকলন'),
),
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_SectionHeader(
title: 'আজকের দোয়া',
icon: Icons.auto_awesome_rounded,
),
const SizedBox(height: 12),
if (_randomDua == null)
const Center(child: CircularProgressIndicator())
else
DuaCard(dua: _randomDua!, onTap: () => _openDua(_randomDua!)),
const SizedBox(height: 8),
Align(
alignment: Alignment.centerRight,
child: TextButton.icon(
onPressed: _nextRandom,
icon: const Icon(Icons.refresh_rounded, size: 18),
label: const Text('অন্য দোয়া দেখুন'),
style: TextButton.styleFrom(
foregroundColor: AppTheme.primary,
),
),
),
const SizedBox(height: 16),
_SectionHeader(
title: 'দ্রুত অ্যাক্সেস',
icon: Icons.flash_on_rounded,
),
const SizedBox(height: 12),
const _QuickAccessGrid(),
const SizedBox(height: 80),
],
),
),
),
],
),
);

void _openDua(Dua dua) => Navigator.push(
context,
MaterialPageRoute(builder: (_) => DuaDetailPage(dua: dua)),
);
}

class \_HeaderBanner extends StatelessWidget {
@override
Widget build(BuildContext context) => Container(
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
child: Stack(
children: [
Positioned(
right: -20,
top: -20,
child: Opacity(
opacity: 0.07,
child: Icon(Icons.star_rounded, size: 200, color: Colors.white),
),
),
Positioned(
left: -30,
bottom: -30,
child: Opacity(
opacity: 0.05,
child: Icon(Icons.star_rounded, size: 160, color: Colors.white),
),
),
Padding(
padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.end,
children: [
Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 6,
),
decoration: BoxDecoration(
color: AppTheme.accent.withOpacity(0.2),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
),
child: const Text(
'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ',
style: TextStyle(
fontFamily: 'serif',
fontSize: 15,
color: AppTheme.accentLight,
),
),
),
const SizedBox(height: 8),
const Text(
'আল্লাহর রহমতে আপনাকে স্বাগতম',
style: TextStyle(fontSize: 16, color: Colors.white70),
),
],
),
),
],
),
);
}

const \_quickItems = [
_QuickItem('সকালের দোয়া', Icons.wb_sunny_rounded, 'morning-and-evening'),
_QuickItem('নামাজের দোয়া', Icons.mosque_rounded, 'salah'),
_QuickItem('ঘুমের দোয়া', Icons.bedtime_rounded, 'sleep'),
_QuickItem('খাবারের দোয়া', Icons.restaurant_rounded, 'eating-and-drinking'),
];

class \_QuickItem {
final String label;
final IconData icon;
final String categoryUrl;
const \_QuickItem(this.label, this.icon, this.categoryUrl);
}

class \_QuickAccessGrid extends StatelessWidget {
const \_QuickAccessGrid();

@override
Widget build(BuildContext context) => GridView.count(
crossAxisCount: 2,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
childAspectRatio: 1.6,
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
children: \_quickItems.map((item) => \_QuickCard(item: item)).toList(),
);
}

class \_QuickCard extends StatelessWidget {
final \_QuickItem item;
const \_QuickCard({required this.item});

@override
Widget build(BuildContext context) => GestureDetector(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (\_) => DuaListByCategory(
categoryUrl: item.categoryUrl,
categoryName: item.label,
),
),
),
child: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [AppTheme.primary.withOpacity(0.85), AppTheme.primaryLight],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: AppTheme.primary.withOpacity(0.2),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(item.icon, color: AppTheme.accentLight, size: 28),
const SizedBox(height: 8),
Text(
item.label,
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.w600,
fontSize: 14,
),
),
],
),
),
),
);
}

// ─────────────────────────────────────────────
// CATEGORY LIST PAGE
// ─────────────────────────────────────────────
class CategoryListPage extends StatefulWidget {
const CategoryListPage({super.key});

@override
State<CategoryListPage> createState() => \_CategoryListPageState();
}

class \_CategoryListPageState extends State<CategoryListPage> {
late Future<List<DuaCategory>> \_future;

@override
void initState() {
super.initState();
// Already warm from \_AppLoader — resolves instantly
\_future = AssetDataService().getCategories();
}

@override
Widget build(BuildContext context) => Scaffold(
appBar: AppBar(title: const Text('সকল বিভাগ')),
body: FutureBuilder<List<DuaCategory>>(
future: _future,
builder: (_, snap) {
if (snap.connectionState != ConnectionState.done) {
return const Center(child: CircularProgressIndicator());
}
final cats = snap.data!;
return ListView.separated(
padding: const EdgeInsets.all(16),
itemCount: cats.length,
separatorBuilder: (_, \_\_) => const SizedBox(height: 10),
itemBuilder: (_, i) => \_CategoryTile(category: cats[i]),
);
},
),
);
}

class \_CategoryTile extends StatelessWidget {
final DuaCategory category;
const \_CategoryTile({required this.category});

@override
Widget build(BuildContext context) => Card(
child: ListTile(
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
leading: Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: AppTheme.primary.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: const Icon(Icons.auto*stories_rounded, color: AppTheme.primary),
),
title: Text(
category.name,
style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
),
subtitle: Text(
category.meta,
style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
),
trailing: const Icon(
Icons.chevron_right_rounded,
color: AppTheme.primary,
),
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (*) => DuaListByCategory(
categoryUrl: category.url,
categoryName: category.name,
),
),
),
),
);
}

// ─────────────────────────────────────────────
// DUA LIST BY CATEGORY
// ─────────────────────────────────────────────
class DuaListByCategory extends StatefulWidget {
final String categoryUrl;
final String categoryName;
const DuaListByCategory({
super.key,
required this.categoryUrl,
required this.categoryName,
});

@override
State<DuaListByCategory> createState() => \_DuaListByCategoryState();
}

class \_DuaListByCategoryState extends State<DuaListByCategory> {
late Future<\_CategoryData> \_future;

@override
void initState() {
super.initState();
\_future = \_load();
}

Future<\_CategoryData> \_load() async {
final results = await Future.wait([
AssetDataService().getSubCategories(),
AssetDataService().getAllDuas(),
]);
final subs = (results[0] as List<DuaSubCategory>)
.where((s) => s.category == widget.categoryUrl)
.toList();
final duas = results[1] as List<Dua>;
return \_CategoryData(subs: subs, allDuas: duas);
}

@override
Widget build(BuildContext context) => Scaffold(
appBar: AppBar(title: Text(widget.categoryName)),
body: FutureBuilder<_CategoryData>(
future: \_future,
builder: (_, snap) {
if (snap.connectionState != ConnectionState.done) {
return const Center(child: CircularProgressIndicator());
}
final data = snap.data!;
if (data.subs.isEmpty) {
return const Center(child: Text('এই বিভাগে কোনো দোয়া নেই'));
}
return ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: data.subs.length,
itemBuilder: (_, i) {
final sub = data.subs[i];
final duas = data.allDuas
.where((d) => sub.duaIds.contains(d.duaId))
.toList();
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (i > 0) const SizedBox(height: 16),
\_SubCatHeader(title: sub.title),
const SizedBox(height: 8),
...duas.map(
(d) => Padding(
padding: const EdgeInsets.only(bottom: 10),
child: DuaCard(
dua: d,
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => DuaDetailPage(dua: d),
),
),
),
),
),
],
);
},
);
},
),
);
}

class \_CategoryData {
final List<DuaSubCategory> subs;
final List<Dua> allDuas;
\_CategoryData({required this.subs, required this.allDuas});
}

class \_SubCatHeader extends StatelessWidget {
final String title;
const \_SubCatHeader({required this.title});

@override
Widget build(BuildContext context) => Row(
children: [
Container(
width: 4,
height: 20,
color: AppTheme.accent,
margin: const EdgeInsets.only(right: 10),
),
Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
color: AppTheme.primaryDark,
),
),
),
],
);
}

// ─────────────────────────────────────────────
// DUA CARD (shared list item widget)
// ─────────────────────────────────────────────
class DuaCard extends StatefulWidget {
final Dua dua;
final VoidCallback onTap;
const DuaCard({super.key, required this.dua, required this.onTap});

@override
State<DuaCard> createState() => \_DuaCardState();
}

class \_DuaCardState extends State<DuaCard> {
late bool \_fav;

@override
void initState() {
super.initState();
\_fav = FavoritesStore().isFav(widget.dua.duaId);
}

@override
Widget build(BuildContext context) => Card(
child: InkWell(
onTap: widget.onTap,
borderRadius: BorderRadius.circular(16),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Header row
Row(
children: [
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 4,
),
decoration: BoxDecoration(
color: AppTheme.primary.withOpacity(0.1),
borderRadius: BorderRadius.circular(20),
),
child: Text(
'#${widget.dua.duaId}',
style: const TextStyle(
color: AppTheme.primary,
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
widget.dua.title,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: AppTheme.textPrimary,
),
maxLines: 2,
overflow: TextOverflow.ellipsis,
),
),
// Favorite toggle
ListenableBuilder(
listenable: FavoritesStore(),
builder: (_, __) {
final fav = FavoritesStore().isFav(widget.dua.duaId);
return IconButton(
icon: Icon(
fav
? Icons.favorite_rounded
: Icons.favorite_border_rounded,
color: fav ? Colors.red : AppTheme.textSecondary,
size: 22,
),
onPressed: () =>
FavoritesStore().toggle(widget.dua.duaId),
);
},
),
],
),
const SizedBox(height: 12),
// Arabic
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: AppTheme.arabicBg,
borderRadius: BorderRadius.circular(10),
border: Border.all(color: AppTheme.divider),
),
child: Text(
widget.dua.arabic,
textAlign: TextAlign.right,
textDirection: TextDirection.rtl,
style: const TextStyle(
fontFamily: 'serif',
fontSize: 20,
height: 1.8,
color: AppTheme.primaryDark,
),
),
),
// Translation preview
if (widget.dua.translation.isNotEmpty) ...[
const SizedBox(height: 10),
Text(
widget.dua.translation,
style: const TextStyle(
fontSize: 13,
color: AppTheme.textSecondary,
height: 1.5,
),
maxLines: 3,
overflow: TextOverflow.ellipsis,
),
],
// Reference
if (widget.dua.reference.isNotEmpty) ...[
const SizedBox(height: 8),
Row(
children: [
const Icon(
Icons.menu_book_rounded,
size: 14,
color: AppTheme.accent,
),
const SizedBox(width: 4),
Text(
widget.dua.reference,
style: const TextStyle(
fontSize: 12,
color: AppTheme.accent,
fontWeight: FontWeight.w500,
),
),
],
),
],
],
),
),
),
);
}

// ─────────────────────────────────────────────
// DUA AUDIO PLAYER
// ─────────────────────────────────────────────
const \_kDuaAudioBaseUrl = 'https://islamicapi.com';

class DuaAudioPlayer extends StatefulWidget {
final String audioUrl;
const DuaAudioPlayer({super.key, required this.audioUrl});

@override
State<DuaAudioPlayer> createState() => \_DuaAudioPlayerState();
}

class \_DuaAudioPlayerState extends State<DuaAudioPlayer> {
late final AudioPlayer \_player;
PlayerState \_playerState = PlayerState.stopped;
Duration \_position = Duration.zero;
Duration \_duration = Duration.zero;
bool \_isBuffering = false;
bool \_hasError = false;

StreamSubscription<PlayerState>? \_stateSub;
StreamSubscription<Duration>? \_positionSub;
StreamSubscription<Duration>? \_durationSub;

@override
void initState() {
super.initState();
\_player = AudioPlayer();
\_stateSub = \_player.onPlayerStateChanged.listen(\_onStateChanged);
\_positionSub = \_player.onPositionChanged.listen((pos) {
if (mounted) setState(() => \_position = pos);
});
\_durationSub = \_player.onDurationChanged.listen((dur) {
if (mounted) setState(() => \_duration = dur);
});
}

void \_onStateChanged(PlayerState state) {
if (!mounted) return;
setState(() {
\_playerState = state;
\_isBuffering = false;
if (state == PlayerState.stopped || state == PlayerState.completed) {
\_position = Duration.zero;
}
});
}

double get \_progress {
if (\_duration.inMilliseconds <= 0) return 0.0;
if (\_playerState == PlayerState.stopped ||
\_playerState == PlayerState.completed) {
return 0.0;
}
return (\_position.inMilliseconds / \_duration.inMilliseconds).clamp(
0.0,
1.0,
);
}

String \_formatTime(Duration d) {
final minutes = d.inMinutes;
final seconds = d.inSeconds % 60;
return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Future<void> \_togglePlayPause() async {
if (\_hasError) setState(() => \_hasError = false);

    try {
      if (_playerState == PlayerState.stopped ||
          _playerState == PlayerState.completed) {
        setState(() => _isBuffering = true);
        await _player.play(UrlSource(widget.audioUrl));
      } else if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else if (_playerState == PlayerState.paused) {
        setState(() => _isBuffering = true);
        await _player.resume();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isBuffering = false;
        });
      }
    }

}

Future<void> _retry() async {
await \_player.stop();
if (!mounted) return;
setState(() {
\_hasError = false;
\_position = Duration.zero;
\_playerState = PlayerState.stopped;
\_isBuffering = true;
});
try {
await \_player.play(UrlSource(widget.audioUrl));
} catch (_) {
if (mounted) {
setState(() {
\_hasError = true;
\_isBuffering = false;
});
}
}
}

@override
void dispose() {
\_stateSub?.cancel();
\_positionSub?.cancel();
\_durationSub?.cancel();
\_player.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
if (\_hasError) {
return SizedBox(
height: 56,
child: Row(
children: [
const Icon(
Icons.error_outline_rounded,
color: AppTheme.error,
size: 20,
),
const SizedBox(width: 8),
const Expanded(
child: Text(
'অডিও লোড হয়নি',
style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
),
),
TextButton(
onPressed: _retry,
style: TextButton.styleFrom(
foregroundColor: AppTheme.primary,
padding: const EdgeInsets.symmetric(horizontal: 8),
minimumSize: Size.zero,
tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
child: const Text('আবার চেষ্টা', style: TextStyle(fontSize: 12)),
),
],
),
);
}

    const timeStyle = TextStyle(fontSize: 12, color: AppTheme.textSecondary);

    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: _isBuffering
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 36,
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppTheme.divider,
                  color: AppTheme.primary,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_position), style: timeStyle),
                    Text(_formatTime(_duration), style: timeStyle),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

}
}

// ─────────────────────────────────────────────
// DUA DETAIL PAGE
// ─────────────────────────────────────────────
class DuaDetailPage extends StatefulWidget {
final Dua dua;
const DuaDetailPage({super.key, required this.dua});

@override
State<DuaDetailPage> createState() => \_DuaDetailPageState();
}

class \_DuaDetailPageState extends State<DuaDetailPage> {
bool \_showTransliteration = true;

void \_copyArabic() {
Clipboard.setData(ClipboardData(text: widget.dua.arabic));
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('আরবি পাঠ কপি হয়েছে'),
backgroundColor: AppTheme.primary,
duration: Duration(seconds: 2),
),
);
}

@override
Widget build(BuildContext context) => Scaffold(
backgroundColor: AppTheme.background,
body: CustomScrollView(
slivers: [
SliverAppBar(
pinned: true,
backgroundColor: AppTheme.primary,
title: Text(
widget.dua.title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
actions: [
// Favorite button — reactive to store changes
ListenableBuilder(
listenable: FavoritesStore(),
builder: (_, __) {
final fav = FavoritesStore().isFav(widget.dua.duaId);
return IconButton(
icon: Icon(
fav
? Icons.favorite_rounded
: Icons.favorite_border_rounded,
color: fav ? Colors.red.shade300 : Colors.white,
),
onPressed: () => FavoritesStore().toggle(widget.dua.duaId),
);
},
),
IconButton(
icon: const Icon(Icons.copy_rounded, color: Colors.white),
onPressed: _copyArabic,
tooltip: 'কপি করুন',
),
],
),
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Introduction
if (widget.dua.introduction.isNotEmpty) ...[
_InfoChip(text: widget.dua.introduction),
const SizedBox(height: 16),
],

                // Arabic + transliteration card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5EDD5), Color(0xFFEEE4C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.dua.arabic,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 24,
                          height: 2.0,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      if (_showTransliteration &&
                          widget.dua.transliteration.isNotEmpty) ...[
                        Divider(
                          color: AppTheme.accent.withOpacity(0.3),
                          height: 24,
                        ),
                        Text(
                          widget.dua.transliteration,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                        ),
                      ],
                      if (widget.dua.audio.isNotEmpty) ...[
                        Divider(
                          color: AppTheme.accent.withOpacity(0.3),
                          height: 24,
                        ),
                        DuaAudioPlayer(
                          audioUrl: '$_kDuaAudioBaseUrl${widget.dua.audio}',
                        ),
                      ],
                    ],
                  ),
                ),

                // Transliteration toggle
                if (widget.dua.transliteration.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _showTransliteration = !_showTransliteration,
                    ),
                    icon: Icon(
                      _showTransliteration
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _showTransliteration ? 'উচ্চারণ লুকান' : 'উচ্চারণ দেখুন',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),

                const SizedBox(height: 8),

                // Translation
                if (widget.dua.translation.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.translate_rounded,
                    title: 'অর্থ',
                    child: Text(
                      widget.dua.translation,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Reference
                if (widget.dua.reference.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.menu_book_rounded,
                    title: 'রেফারেন্স',
                    accent: true,
                    child: Text(
                      widget.dua.reference,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Hadith
                if (widget.dua.hadith != null &&
                    widget.dua.hadith!.translation.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.format_quote_rounded,
                    title: widget.dua.hadith!.title.isNotEmpty
                        ? widget.dua.hadith!.title
                        : 'হাদিস',
                    child: Text(
                      widget.dua.hadith!.translation,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Benefits
                if (widget.dua.benefits != null &&
                    widget.dua.benefits!.points.isNotEmpty) ...[
                  _SectionCard(
                    icon: Icons.stars_rounded,
                    title: 'ফজিলত ও উপকারিতা',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.dua.benefits!.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              widget.dua.benefits!.description,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                            ),
                          ),
                        ...widget.dua.benefits!.points.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 18,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ),

);
}

// ─────────────────────────────────────────────
// SEARCH PAGE
// ─────────────────────────────────────────────
class SearchPage extends StatefulWidget {
const SearchPage({super.key});

@override
State<SearchPage> createState() => \_SearchPageState();
}

class \_SearchPageState extends State<SearchPage> {
List<Dua> \_allDuas = [];
List<Dua> \_results = [];
final TextEditingController \_ctrl = TextEditingController();

@override
void initState() {
super.initState();
// Already in memory from warm-up — immediate
AssetDataService().getAllDuas().then((list) => \_allDuas = list);
}

void \_search(String q) {
final lower = q.toLowerCase().trim();
setState(() {
\_results = lower.isEmpty
? []
: \_allDuas
.where(
(d) =>
d.title.toLowerCase().contains(lower) ||
d.translation.toLowerCase().contains(lower) ||
d.reference.toLowerCase().contains(lower),
)
.toList();
});
}

@override
Widget build(BuildContext context) => Scaffold(
appBar: AppBar(title: const Text('দোয়া খোঁজুন')),
body: Column(
children: [
// Search bar
Container(
color: AppTheme.primary,
padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
child: TextField(
controller: _ctrl,
onChanged: \_search,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
hintText: 'দোয়ার নাম বা অর্থ লিখুন...',
hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
prefixIcon: const Icon(
Icons.search_rounded,
color: Colors.white70,
),
suffixIcon: \_ctrl.text.isNotEmpty
? IconButton(
icon: const Icon(
Icons.clear_rounded,
color: Colors.white70,
),
onPressed: () {
\_ctrl.clear();
\_search('');
},
)
: null,
filled: true,
fillColor: Colors.white.withOpacity(0.15),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),
),
// Results
Expanded(
child: \_ctrl.text.isEmpty
? \_SearchEmpty()
: \_results.isEmpty
? const Center(
child: Text(
'কোনো ফলাফল পাওয়া যায়নি',
style: TextStyle(color: AppTheme.textSecondary),
),
)
: ListView.separated(
padding: const EdgeInsets.all(16),
itemCount: \_results.length,
separatorBuilder: (_, \__) => const SizedBox(height: 10),
itemBuilder: (_, i) => DuaCard(
dua: _results[i],
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => DuaDetailPage(dua: \_results[i]),
),
),
),
),
),
],
),
);
}

class \_SearchEmpty extends StatelessWidget {
@override
Widget build(BuildContext context) => Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.search_rounded,
size: 72,
color: AppTheme.primary.withOpacity(0.2),
),
const SizedBox(height: 16),
const Text(
'দোয়ার নাম বা শব্দ লিখে খুঁজুন',
style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
),
],
),
);
}

// ─────────────────────────────────────────────
// FAVORITES PAGE
// ─────────────────────────────────────────────
class FavoritesPage extends StatelessWidget {
const FavoritesPage({super.key});

@override
Widget build(BuildContext context) => Scaffold(
appBar: AppBar(title: const Text('পছন্দের দোয়া')),
body: ListenableBuilder(
listenable: FavoritesStore(),
builder: (\_, \_\_) {
final ids = FavoritesStore().all;
if (ids.isEmpty) return \_FavEmpty();

        return FutureBuilder<List<Dua>>(
          future: AssetDataService().getAllDuas().then(
            (all) => all.where((d) => ids.contains(d.duaId)).toList(),
          ),
          builder: (_, snap) {
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final favs = snap.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => DuaCard(
                dua: favs[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DuaDetailPage(dua: favs[i]),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),

);
}

class \_FavEmpty extends StatelessWidget {
@override
Widget build(BuildContext context) => Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.favorite_border_rounded,
size: 72,
color: AppTheme.primary.withOpacity(0.2),
),
const SizedBox(height: 16),
const Text(
'এখনো কোনো দোয়া পছন্দ করেননি',
style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
),
const SizedBox(height: 8),
const Text(
'❤️ চিহ্ন চাপ দিয়ে দোয়া সংরক্ষণ করুন',
style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
),
],
),
);
}

// ─────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────
class \_SectionHeader extends StatelessWidget {
final String title;
final IconData icon;
const \_SectionHeader({required this.title, required this.icon});

@override
Widget build(BuildContext context) => Row(
children: [
Icon(icon, color: AppTheme.accent, size: 20),
const SizedBox(width: 8),
Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w700,
color: AppTheme.textPrimary,
),
),
],
);
}

class \_InfoChip extends StatelessWidget {
final String text;
const \_InfoChip({required this.text});

@override
Widget build(BuildContext context) => Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
decoration: BoxDecoration(
color: AppTheme.primary.withOpacity(0.08),
borderRadius: BorderRadius.circular(10),
border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
),
child: Row(
children: [
const Icon(
Icons.info_outline_rounded,
size: 16,
color: AppTheme.primary,
),
const SizedBox(width: 8),
Expanded(
child: Text(
text,
style: const TextStyle(
fontSize: 13,
color: AppTheme.primary,
height: 1.4,
),
),
),
],
),
);
}

class \_SectionCard extends StatelessWidget {
final IconData icon;
final String title;
final Widget child;
final bool accent;
const \_SectionCard({
required this.icon,
required this.title,
required this.child,
this.accent = false,
});

@override
Widget build(BuildContext context) => Card(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
icon,
size: 18,
color: accent ? AppTheme.accent : AppTheme.primary,
),
const SizedBox(width: 8),
Text(
title,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: accent ? AppTheme.accent : AppTheme.primary,
),
),
],
),
Divider(
color: (accent ? AppTheme.accent : AppTheme.primary).withOpacity(
0.15,
),
height: 16,
),
child,
],
),
),
);
}
