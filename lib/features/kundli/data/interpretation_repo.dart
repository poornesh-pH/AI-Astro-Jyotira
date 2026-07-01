import 'dart:convert';
import '../../../core/config.dart';
import '../../../core/network/api_client.dart';
 
enum ReadingType { daily, report, compat, ask, dosha, muhurat }
 
extension ReadingTypeApi on ReadingType {
  /// Server-side prompt key. dosha/muhurat reuse the 'report' generator with a
  /// focus flag so the backend stays small and tokens stay low.
  String get apiType => switch (this) {
        ReadingType.daily => 'daily',
        ReadingType.report => 'report',
        ReadingType.compat => 'compat',
        ReadingType.ask => 'ask',
        ReadingType.dosha => 'report',
        ReadingType.muhurat => 'report',
      };
 
  String? get focus => switch (this) {
        ReadingType.dosha => 'dosha_and_remedies',
        ReadingType.muhurat => 'auspicious_timing',
        _ => null,
      };
}
 
class InterpretationException implements Exception {
  final String message;
  const InterpretationException(this.message);
  @override
  String toString() => message;
}
 
/// Calls our own backend (server/interpret.ts), never the LLM directly.
/// The backend caches by chart hash + type + lang, so repeated reads cost
/// zero tokens.
class InterpretationRepo {
  InterpretationRepo(this._client);
  final ApiClient _client;
 
  Future<String> interpret({
    required String chartHash,
    required Map<String, dynamic> ground,
    required ReadingType type,
    required String lang,
    String? question,
  }) async {
    if (!AppConfig.apiConfigured) {
      throw const InterpretationException(
        'Reading service is not configured yet. Add API_BASE_URL to enable AI guidance.',
      );
    }
 
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/interpret');
    final res = await _client.postJson(
      uri,
      body: jsonEncode({
        'chartHash': chartHash,
        'ground': ground,
        'type': type.apiType,
        if (type.focus != null) 'focus': type.focus,
        'lang': lang,
        if (question != null) 'question': question,
      }),
    );
 
    if (res.statusCode != 200) {
      throw InterpretationException('Service unavailable (${res.statusCode}).');
    }
 
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final text = data['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw const InterpretationException('Empty interpretation received.');
    }
    return text.trim();
  }
}
