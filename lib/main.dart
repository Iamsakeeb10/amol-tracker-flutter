// ============================================================
// APP 1 — Tanzil Quran Metadata
// Source: http://tanzil.net/res/text/metadata/quran-data.xml
// No API key required.
// pubspec deps: http, xml
// ============================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

void main() => runApp(const TanzilApp());

class TanzilApp extends StatelessWidget {
  const TanzilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanzil Quran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      home: const SuraListScreen(),
    );
  }
}

// ── Model ────────────────────────────────────────────────────

class SuraMeta {
  final int index;
  final String name; // Arabic name
  final String tname; // English transliteration
  final String ename; // English meaning
  final int ayas; // verse count
  final int revelationOrder;
  final String type; // Meccan / Medinan

  const SuraMeta({
    required this.index,
    required this.name,
    required this.tname,
    required this.ename,
    required this.ayas,
    required this.revelationOrder,
    required this.type,
  });
}

// ── Repository ───────────────────────────────────────────────

class TanzilRepository {
  static const _url = 'http://tanzil.net/res/text/metadata/quran-data.xml';

  Future<List<SuraMeta>> fetchSuras() async {
    final res = await http.get(Uri.parse(_url));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final doc = XmlDocument.parse(res.body);
    final suraNodes = doc.findAllElements('sura');
    return suraNodes.map((n) {
      return SuraMeta(
        index: int.parse(n.getAttribute('index') ?? '0'),
        name: n.getAttribute('name') ?? '',
        tname: n.getAttribute('tname') ?? '',
        ename: n.getAttribute('ename') ?? '',
        ayas: int.parse(n.getAttribute('ayas') ?? '0'),
        revelationOrder: int.parse(n.getAttribute('order') ?? '0'),
        type: n.getAttribute('type') ?? '',
      );
    }).toList();
  }
}

// ── Screen ───────────────────────────────────────────────────

class SuraListScreen extends StatefulWidget {
  const SuraListScreen({super.key});

  @override
  State<SuraListScreen> createState() => _SuraListScreenState();
}

class _SuraListScreenState extends State<SuraListScreen> {
  final _repo = TanzilRepository();
  late Future<List<SuraMeta>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchSuras();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: const Text('القرآن الكريم — Tanzil'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SuraMeta>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        setState(() => _future = _repo.fetchSuras()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final suras = snap.data!;
          return ListView.separated(
            itemCount: suras.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (ctx, i) => _SuraTile(sura: suras[i]),
          );
        },
      ),
    );
  }
}

class _SuraTile extends StatelessWidget {
  final SuraMeta sura;
  const _SuraTile({required this.sura});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMeccan = sura.type.toLowerCase() == 'meccan';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        child: Text(
          '${sura.index}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              sura.tname,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            sura.name,
            style: TextStyle(
              fontSize: 16,
              color: cs.primary,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
      subtitle: Text(
        '${sura.ename}  •  ${sura.ayas} verses  •  Revelation #${sura.revelationOrder}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Chip(
        label: Text(
          isMeccan ? 'Meccan' : 'Medinan',
          style: TextStyle(
            fontSize: 11,
            color: isMeccan ? Colors.brown[800] : Colors.blue[800],
          ),
        ),
        backgroundColor: isMeccan ? Colors.brown[50] : Colors.blue[50],
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
