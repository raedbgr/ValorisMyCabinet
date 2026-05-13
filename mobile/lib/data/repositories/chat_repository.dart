import '../models/message_model.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';

class ChatRepository {
  final ApiClient _api = ApiClient.instance;

  final List<MessageModel> _messages = [
    MessageModel(
      id: 'welcome',
      role: MessageRole.assistant,
      content:
          "Bonjour 👋 Je suis votre assistant comptable. Posez-moi une question sur vos obligations fiscales, vos documents ou vos échéances.",
      timestamp: DateTime.now(),
    ),
  ];

  List<MessageModel> getMessages() => List.unmodifiable(_messages);

  Future<void> addMessage(MessageModel message) async {
    _messages.add(message);
  }

  Future<void> updateLastAssistantMessage(String content,
      {bool isStreaming = true}) async {
    final idx = _messages.lastIndexWhere((m) => m.role == MessageRole.assistant);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        content: content,
        isStreaming: isStreaming,
      );
    }
  }

  Future<String> sendChat({
    required String clientName,
    required List<MessageModel> history,
  }) async {
    final payload = {
      'client_name': clientName,
      'messages': history
          .where((m) => m.content.trim().isNotEmpty)
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList(),
    };

    final data = await _api.post('/chat', body: payload);
    if (data is Map && data['reply'] != null) {
      return data['reply'].toString();
    }
    throw const ApiException('Réponse invalide du serveur');
  }

  Future<void> setFeedback(String messageId, FeedbackVote vote) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(feedback: vote);
    }
  }

  Future<bool> submitFeedback({
    required String messageId,
    required String clientId,
    required bool isPositive,
    String? comments,
  }) async {
    try {
      final data = await _api.post('/chat/feedback', body: {
        'message_id': messageId,
        'client_id': clientId,
        'is_positive': isPositive,
        if (comments != null) 'comments': comments,
      });
      return data is Map && data['success'] == true;
    } on ApiException {
      return false;
    }
  }

  String get defaultClientId => ApiConfig.defaultClientId;
}
