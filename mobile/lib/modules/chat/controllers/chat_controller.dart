import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatController extends GetxController {
  final _repo = ChatRepository();

  final messages = <MessageModel>[].obs;
  final isThinking = false.obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();

  static const _quickReplies = ['Oui, à 9h', 'Pas besoin'];
  final quickReplies = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    messages.value = _repo.getMessages();
    quickReplies.value = _quickReplies;
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    textController.clear();
    quickReplies.clear();

    final userMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    await _repo.addMessage(userMsg);
    messages.value = _repo.getMessages();
    _scrollToBottom();

    // Simulate streaming assistant response
    isThinking.value = true;
    await Future.delayed(const Duration(milliseconds: 1200));

    final assistantMsg = MessageModel(
      id: '${DateTime.now().millisecondsSinceEpoch}a',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    await _repo.addMessage(assistantMsg);
    messages.value = _repo.getMessages();
    isThinking.value = false;

    // Stream mock response
    const response =
        "Parfait ! Je vous enverrai un rappel demain matin à 9h si les factures du 15 et 22 juillet ne sont pas encore uploadées. Voulez-vous que je planifie aussi un créneau avec votre comptable ?";
    var streamed = '';
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 18));
      streamed += response[i];
      await _repo.updateLastAssistantMessage(streamed, isStreaming: true);
      messages.value = _repo.getMessages();
      _scrollToBottom();
    }

    await _repo.updateLastAssistantMessage(response, isStreaming: false);
    messages.value = _repo.getMessages();
  }

  Future<void> setFeedback(String messageId, FeedbackVote vote) async {
    await _repo.setFeedback(messageId, vote);
    messages.value = _repo.getMessages();
  }

  void toggleToolTrace(String messageId) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = messages[idx];
    if (msg.toolTrace == null) return;
    msg.toolTrace!.expanded = !msg.toolTrace!.expanded;
    messages.refresh();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
