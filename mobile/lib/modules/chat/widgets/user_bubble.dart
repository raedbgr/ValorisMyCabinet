import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/message_model.dart';

class UserBubble extends StatelessWidget {
  final MessageModel message;

  const UserBubble({super.key, required this.message});

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.white,
                letterSpacing: -0.1,
                height: 1.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.text3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
