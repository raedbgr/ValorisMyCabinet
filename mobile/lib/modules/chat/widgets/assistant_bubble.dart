import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/message_model.dart';

class AssistantBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onThumbsUp;
  final VoidCallback? onThumbsDown;
  final VoidCallback? onToggleTrace;

  const AssistantBubble({
    super.key,
    required this.message,
    this.onThumbsUp,
    this.onThumbsDown,
    this.onToggleTrace,
  });

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.toolTrace != null)
          _ToolCallTrace(
            trace: message.toolTrace!,
            onToggle: onToggleTrace,
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.88,
          ),
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
            child: message.isStreaming && message.content.isEmpty
                ? _ThinkingDots()
                : _buildContent(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.text3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            if (!message.isStreaming) ...[
              _FeedbackButton(
                icon: Icons.thumb_up_outlined,
                isActive: message.feedback == FeedbackVote.up,
                activeColor: AppColors.green,
                onTap: onThumbsUp,
              ),
              const SizedBox(width: 2),
              _FeedbackButton(
                icon: Icons.thumb_down_outlined,
                isActive: message.feedback == FeedbackVote.down,
                activeColor: AppColors.red,
                onTap: onThumbsDown,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Parse basic **bold** markdown
    final text = message.content;
    final spans = <InlineSpan>[];
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in boldPattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14.5,
          color: AppColors.text,
          letterSpacing: -0.1,
          height: 1.45,
        ),
        children: spans,
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.text3
                  .withAlpha(((_controllers[i].value * 0.6 + 0.4) * 255).round()),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _ToolCallTrace extends StatelessWidget {
  final ToolCallTrace trace;
  final VoidCallback? onToggle;

  const _ToolCallTrace({required this.trace, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: trace.expanded
            ? const EdgeInsets.all(12)
            : const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderS, style: BorderStyle.solid),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, size: 13, color: AppColors.amber),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    trace.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.text2,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.05,
                    ),
                  ),
                ),
                Icon(
                  trace.expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 14,
                  color: AppColors.text3,
                ),
              ],
            ),
            if (trace.expanded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: trace.calls.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.text2,
                            letterSpacing: -0.1,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: c.tool,
                              style: const TextStyle(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '(${c.args})',
                              style: const TextStyle(color: AppColors.text3),
                            ),
                            TextSpan(
                              text: ' → ${c.result}',
                              style: const TextStyle(color: AppColors.green),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _FeedbackButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 13,
          color: isActive ? activeColor : AppColors.text3,
        ),
      ),
    );
  }
}
