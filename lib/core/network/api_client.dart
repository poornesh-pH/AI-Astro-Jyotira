import 'dart:async';
import 'package:http/http.dart' as http;
 
/// Thin HTTP wrapper: shared client, timeout, bounded retry with backoff on
/// transient failures. Prevents socket leaks by reusing one client instance.
class ApiClient {
  ApiClient([http.Client? client]) : _client = client ?? http.Client();
 
  final http.Client _client;
  static const _timeout = Duration(seconds: 30);
  static const _maxRetries = 2;
 
  Future<http.Response> postJson(
    Uri uri, {
    required String body,
    Map<String, String> headers = const {},
  }) async {
    final merged = {'content-type': 'application/json', ...headers};
    var attempt = 0;
    while (true) {
      try {
        final res = await _client
            .post(uri, headers: merged, body: body)
            .timeout(_timeout);
        // Retry only on transient upstream errors.
        if (res.statusCode >= 500 && attempt < _maxRetries) {
          attempt++;
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        return res;
      } on TimeoutException {
        if (attempt >= _maxRetries) rethrow;
        attempt++;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }
 
  void dispose() => _client.close();
}
