import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/empty_state.dart';
import 'widgets/message_input_bar.dart';

/// Chat screen with message list and input
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('New Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Chat History'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Clear Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<ChatProvider, SettingsProvider>(
        builder: (context, chat, settings, child) {
          if (!settings.isConfigured) {
            return EmptyState(
              icon: Icons.key,
              title: 'API Not Configured',
              subtitle: 'Please configure your OpenAI API key in settings',
              action: FilledButton(
                onPressed: () => _openSettings(),
                child: const Text('Open Settings'),
              ),
            );
          }

          return Column(
            children: [
              if (chat.error != null) _buildErrorBanner(chat),
              Expanded(
                child: chat.hasMessages
                    ? _buildMessageList(chat)
                    : _buildEmptyState(),
              ),
              MessageInputBar(
                hintText: 'Ask me anything...',
                enabled: !chat.isStreaming,
                isLoading: chat.isStreaming,
                onSend: (message) {
                  chat.sendMessage(message, model: settings.chatModel);
                  _scrollToBottom();
                },
                onStop: chat.isStreaming ? () => chat.cancelStream() : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(ChatProvider chat) {
    final colorScheme = Theme.of(context).colorScheme;

    return MaterialBanner(
      content: Text(chat.error ?? 'An error occurred'),
      backgroundColor: colorScheme.errorContainer,
      contentTextStyle: TextStyle(color: colorScheme.onErrorContainer),
      leading: Icon(Icons.error, color: colorScheme.error),
      actions: [
        TextButton(
          onPressed: () => chat.retryLastMessage(),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildMessageList(ChatProvider chat) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        return ChatBubble(
          message: message,
          onRetry:
              message.hasError ? () => chat.retryLastMessage() : null,
          onDelete: () => chat.deleteMessage(message.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'Start a Conversation',
      subtitle: 'Send a message to begin chatting with AI',
    );
  }

  void _handleMenuAction(String action) {
    final chat = context.read<ChatProvider>();

    switch (action) {
      case 'new':
        chat.newChat();
        break;
      case 'history':
        _showHistoryBottomSheet();
        break;
      case 'clear':
        _showClearConfirmation();
        break;
    }
  }

  void _showHistoryBottomSheet() {
    final chat = context.read<ChatProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Chat History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: chat.sessions.isEmpty
                    ? const Center(child: Text('No chat history'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: chat.sessions.length,
                        itemBuilder: (context, index) {
                          final session = chat.sessions[index];
                          return ListTile(
                            title: Text(
                              session.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${session.messageCount} messages',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                chat.deleteSession(session.id);
                              },
                            ),
                            onTap: () {
                              chat.selectSession(session.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will clear the current conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }
}
