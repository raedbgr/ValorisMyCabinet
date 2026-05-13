import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/api_client.dart';
import '../../auth/controllers/auth_controller.dart';

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

  String get _clientName {
    if (Get.isRegistered<AuthController>()) {
      final u = Get.find<AuthController>().currentUser.value;
      if (u != null) return u.fullName;
    }
    return 'Client';
  }

  String get _clientId {
    if (Get.isRegistered<AuthController>()) {
      final u = Get.find<AuthController>().currentUser.value;
      if (u != null) return u.id;
    }
    return _repo.defaultClientId;
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

    isThinking.value = true;

    final assistantMsg = MessageModel(
      id: '${DateTime.now().millisecondsSinceEpoch}a',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    await _repo.addMessage(assistantMsg);
    messages.value = _repo.getMessages();

    String reply;
    try {
      reply = await _repo.sendChat(
        clientName: _clientName,
        history: _repo
            .getMessages()
            .where((m) => !m.isStreaming)
            .toList(),
      );
    } on ApiException catch (e) {
      reply =
          "Je n'ai pas pu joindre le serveur (${e.message}). Réessayez plus tard.";
    } catch (_) {
      reply = "Une erreur inattendue est survenue.";
    }

    isThinking.value = false;

    // Pseudo-streaming for UX consistency
    var streamed = '';
    for (int i = 0; i < reply.length; i++) {
      streamed += reply[i];
      await _repo.updateLastAssistantMessage(streamed, isStreaming: true);
      messages.value = _repo.getMessages();
      if (i % 4 == 0) {
        await Future.delayed(const Duration(milliseconds: 12));
        _scrollToBottom();
      }
    }

    await _repo.updateLastAssistantMessage(reply, isStreaming: false);
    messages.value = _repo.getMessages();
    _scrollToBottom();
  }

  Future<void> setFeedback(String messageId, FeedbackVote vote) async {
    await _repo.setFeedback(messageId, vote);
    messages.value = _repo.getMessages();
    await _repo.submitFeedback(
      messageId: messageId,
      clientId: _clientId,
      isPositive: vote == FeedbackVote.up,
    );
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
