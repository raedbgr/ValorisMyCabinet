enum MessageRole { user, assistant }

enum FeedbackVote { up, down }

class ToolCallTrace {
  final String label;
  final List<ToolCallEntry> calls;
  bool expanded;

  ToolCallTrace({
    required this.label,
    required this.calls,
    this.expanded = false,
  });
}

class ToolCallEntry {
  final String tool;
  final String args;
  final String result;

  const ToolCallEntry({
    required this.tool,
    required this.args,
    required this.result,
  });
}

class MessageModel {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  FeedbackVote? feedback;
  final ToolCallTrace? toolTrace;
  final bool isStreaming;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.feedback,
    this.toolTrace,
    this.isStreaming = false,
  });

  MessageModel copyWith({
    String? content,
    bool? isStreaming,
    FeedbackVote? feedback,
    ToolCallTrace? toolTrace,
  }) {
    return MessageModel(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      feedback: feedback ?? this.feedback,
      toolTrace: toolTrace ?? this.toolTrace,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
