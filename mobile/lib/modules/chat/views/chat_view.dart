import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/message_model.dart';
import '../controllers/chat_controller.dart';
import '../widgets/assistant_bubble.dart';
import '../widgets/user_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/quick_replies.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList(context)),
          _buildQuickReplies(),
          Obx(
            () => ChatInputBar(
              controller: controller.textController,
              isThinking: controller.isThinking.value,
              onSend: () =>
                  controller.sendMessage(controller.textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Assistant MyCabinet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'En ligne',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return Obx(() {
      final msgs = controller.messages;
      final isThinking = controller.isThinking.value;
      // +1 for day divider, +1 if thinking indicator active
      final total = msgs.length + 1 + (isThinking ? 1 : 0);

      return ListView.builder(
        controller: controller.scrollController,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        itemCount: total,
        itemBuilder: (_, i) {
          // reverse: true → index 0 renders at bottom
          // last index (total-1) renders at top → day divider
          if (i == total - 1) return _DayDivider("Aujourd'hui · 09:24");

          // index 0 = thinking indicator if active (stays at bottom)
          if (isThinking && i == 0) return _ThinkingIndicator();

          // map remaining indices to messages newest-first
          final msgIndex = msgs.length - 1 - (isThinking ? i - 1 : i);
          if (msgIndex < 0 || msgIndex >= msgs.length) {
            return const SizedBox.shrink();
          }

          final msg = msgs[msgIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: msg.role == MessageRole.assistant
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: AssistantBubble(
                      message: msg,
                      onThumbsUp: () =>
                          controller.setFeedback(msg.id, FeedbackVote.up),
                      onThumbsDown: () =>
                          controller.setFeedback(msg.id, FeedbackVote.down),
                      onToggleTrace: msg.toolTrace != null
                          ? () => controller.toggleToolTrace(msg.id)
                          : null,
                    ),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: UserBubble(message: msg),
                  ),
          );
        },
      );
    });
  }

  Widget _buildQuickReplies() {
    return Obx(() {
      if (controller.quickReplies.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: QuickReplies(
            options: controller.quickReplies,
            onSelect: (text) {
              controller.textController.text = text;
              controller.sendMessage(text);
            },
          ),
        ),
      );
    });
  }
}

class _DayDivider extends StatelessWidget {
  final String label;
  const _DayDivider(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.text3,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return _Dot(delay: i * 150);
            }),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color:
              AppColors.text3.withAlpha(((_ctrl.value * 0.6 + 0.4) * 255).round()),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
