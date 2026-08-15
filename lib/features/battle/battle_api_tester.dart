import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/battle_providers.dart';

/// A simple tester function to verify the Battle API.
/// You can trigger this from any temporary button in your app, e.g.:
/// ElevatedButton(
///   onPressed: () => runBattleApiTest(ref),
///   child: Text('Test Battle API'),
/// )
Future<void> runBattleApiTest(WidgetRef ref) async {
  final repo = ref.read(battleRepositoryProvider);

  try {
    debugPrint('--- Starting Battle API Test ---');
    
    // 1. Create a battle
    debugPrint('1. Creating battle...');
    final createRes = await repo.createBattle(
      topicId: 'test_topic', 
      questionCount: 3, 
      timeLimitSeconds: 300, 
      maxPlayers: 2
    );
    final code = createRes.code;
    debugPrint('Battle created with code: $code');
    
    // 2. Start the battle
    debugPrint('2. Starting battle...');
    await repo.startBattle(code: code);
    debugPrint('Battle $code started successfully.');
    
    // 3. Submit an answer (assuming a hardcoded selectedIndex for test)
    debugPrint('3. Submitting answer...');
    await repo.submitAllAnswers(
      code: code, 
      answers: [
        {'questionId': '123', 'selectedIndex': 1, 'responseTimeMs': 2000}
      ]
    );
    debugPrint('Answers submitted.');
    
    debugPrint('--- Battle API Test Complete ---');
  } catch (e, st) {
    debugPrint('Battle API Test Failed: $e');
    debugPrint(st.toString());
  }
}
