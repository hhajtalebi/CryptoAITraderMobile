import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/data/secure_vault.dart';

class AssistantService {
  final SecureVault vault;
  final http.Client client;
  AssistantService(this.vault, {http.Client? client})
    : client = client ?? http.Client();
  Future<String> ask(String question, String context) async {
    final endpoint = await vault.read('assistant', 'endpoint'),
        model = await vault.read('assistant', 'model'),
        key = await vault.read('assistant', 'key');
    final uri = Uri.tryParse(endpoint ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        key == null ||
        key.isEmpty ||
        model == null ||
        model.isEmpty) {
      throw StateError('ai_setup');
    }
    final target = uri.replace(
      path: '${uri.path.replaceAll(RegExp(r'/$'), '')}/chat/completions',
    );
    final response = await client
        .post(
          target,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a cautious crypto research explainer. Answer in the user language. Never claim certainty or execute trades. No tools or order access. Explain missing evidence. Public market context: $context',
              },
              {'role': 'user', 'content': question},
            ],
            'max_tokens': 700,
          }),
        )
        .timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) throw StateError('ai_error');
    final data = jsonDecode(response.body),
        answer = data['choices']?[0]?['message']?['content'];
    if (answer is! String || answer.isEmpty) throw StateError('ai_error');
    return answer;
  }

  void dispose() => client.close();
}
