import '../models/message_model.dart';

class ChatRepository {
  // Mock conversation — replace with real backend SSE endpoint
  final List<MessageModel> _messages = [
    MessageModel(
      id: 'm1',
      role: MessageRole.assistant,
      content:
          "Bonjour Marie 👋 Je viens de regarder votre déclaration TVA de juillet et il manque deux pièces.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 46)),
      toolTrace: ToolCallTrace(
        label: 'Consultation de vos documents — 3 outils',
        expanded: false,
        calls: [
          ToolCallEntry(
            tool: 'list_documents',
            args: 'category="facture", periode="2026-07"',
            result: '14 trouvés',
          ),
          ToolCallEntry(
            tool: 'check_tva',
            args: 'periode="2026-07"',
            result: '2 manquants',
          ),
          ToolCallEntry(
            tool: 'match_releve',
            args: 'compte="LCL"',
            result: '2 mouvts. orphelins',
          ),
        ],
      ),
    ),
    MessageModel(
      id: 'm2',
      role: MessageRole.assistant,
      content:
          "Plus précisément, les factures du **15** et **22 juillet** ne sont pas encore enregistrées. D'après votre relevé LCL, deux mouvements de **148,50 €** et **312,00 €** correspondent à ces dates.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 46)),
    ),
    MessageModel(
      id: 'm3',
      role: MessageRole.user,
      content: "Ah oui, je les ai au magasin. Je peux les scanner ce soir vers 19h.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 39)),
    ),
    MessageModel(
      id: 'm4',
      role: MessageRole.assistant,
      content:
          "Parfait. L'échéance est le **20 août** — dans 5 jours. Voulez‑vous que je vous envoie un rappel demain matin si elles ne sont pas encore là ?",
      timestamp: DateTime.now().subtract(const Duration(minutes: 39)),
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

  Future<void> setFeedback(String messageId, FeedbackVote vote) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(feedback: vote);
    }
  }
}
