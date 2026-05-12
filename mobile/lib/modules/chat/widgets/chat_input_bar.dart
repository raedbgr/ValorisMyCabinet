import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isThinking;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isThinking = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderS),
              ),
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isThinking,
                textAlignVertical: TextAlignVertical.center,
                expands: true,
                maxLines: null,
                minLines: null,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.text,
                  letterSpacing: -0.1,
                ),
                decoration: const InputDecoration(
                  hintText: "Écrivez à l'assistant…",
                  hintStyle: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.text3,
                    letterSpacing: -0.1,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  isDense: false,
                ),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _hasText && !widget.isThinking ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText && !widget.isThinking
                    ? AppColors.brand
                    : AppColors.bgSunk,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward,
                size: 18,
                color: _hasText && !widget.isThinking
                    ? Colors.white
                    : AppColors.text3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend();
    }
  }
}
