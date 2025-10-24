import 'package:lingua_arv1/api/3d_models_mapping.dart';
import 'package:lingua_arv1/repositories/Api_repository.dart';

class ModelService {
  final GeminiService _geminiService;

  ModelService(this._geminiService);

  String? getModelUrl(String input) {
    final upper = input.toUpperCase();
    return letterModels[upper];
  }

  Future<List<String>> findMatchingModels(String input) async {
    final normalizedInput = input.trim();

    print('\n=== GEMINI TRANSLATION FLOW START ===');
    print('📥 INPUT: "$input"');

    if (normalizedInput.isEmpty) {
      print('🛑 EMPTY INPUT: Returning empty list');
      print('=== GEMINI TRANSLATION FLOW END (Empty) ===\n');
      return [];
    }

    // ALWAYS use Gemini for translation
    print('🤖 GEMINI: Starting AI interpretation...');
    try {
      final allowedTokens = letterModels.keys.toList();
      final aiTokens =
          await _geminiService.interpretToFslTokens(input, allowedTokens);

      final filteredTokens = aiTokens
          .where((token) => token.isNotEmpty && letterModels.containsKey(token))
          .toList();

      if (filteredTokens.isNotEmpty) {
        print('✅ GEMINI SUCCESS: Translated to FSL tokens: $filteredTokens');
        print('=== GEMINI TRANSLATION FLOW END (Success) ===\n');
        return filteredTokens;
      } else {
        print('❌ GEMINI: No valid tokens found, returning empty');
        print('=== GEMINI TRANSLATION FLOW END (No Tokens) ===\n');
        return [];
      }
    } catch (e) {
      print('❌ GEMINI FAILED: $e, returning empty');
      print('=== GEMINI TRANSLATION FLOW END (Error) ===\n');
      return [];
    }
  }

  List<String> getAllAvailableModels() {
    return letterModels.keys.toList();
  }
}
