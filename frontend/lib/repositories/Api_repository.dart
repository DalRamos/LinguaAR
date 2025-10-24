import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyCU721k6WWRFfzJFoZYN81kNrYMkN6scDI';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<List<String>> interpretToFslTokens(
      String input, List<String> allowedTokens) async {
    print('🎯 GEMINI: Starting translation for: "$input"');
    print('📋 GEMINI: Allowed tokens count: ${allowedTokens.length}');

    final allowedTokensString = allowedTokens.join(', ');

    final prompt = """
You are an assistant for Filipino Sign Language (FSL) translation.
Given the input sentence: "$input"

Return a minimal sequence of FSL tokens (words or short phrases) that best represent the sentence,
but ONLY use tokens from this permitted list (case-insensitive):
$allowedTokensString

**IMPORTANT RULES:**
1. If a complete word exists in the allowed tokens, use THAT WORD only (don't break it down)
2. If a word does NOT exist in allowed tokens, break it down into INDIVIDUAL LETTERS
3. Never mix whole words and letters for the same word
4. Return tokens separated by commas only

Examples:
- Input: "rex" → Output: "R,E,X" (if "REX" not in allowed tokens)
- Input: "hello" → Output: "HELLO" (if "HELLO" in allowed tokens)
- Input: "hello rex" → Output: "HELLO,R,E,X" (if "HELLO" exists but "REX" doesn't)
- Input: "cat" → Output: "C,A,T" (if "CAT" not in allowed tokens)

Respond with tokens separated by commas only. Do not add any extra words or explanation.
""";

    try {
      print('🚀 GEMINI: Calling API...');
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      print('✅ GEMINI: API Response received: "$text"');

      final rawTokens = text
          .split(RegExp(r'[\n,;]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final tokensUpper = rawTokens.map((t) => t.toUpperCase()).toList();

      print('🔤 GEMINI: Parsed tokens: $tokensUpper');
      return tokensUpper;
    } catch (e) {
      print('❌ GEMINI: API Error: $e');
      rethrow;
    }
  }
}
