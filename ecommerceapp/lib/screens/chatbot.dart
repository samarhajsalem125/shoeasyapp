import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  final String token;
  final String userId;

  const ChatbotScreen({super.key, required this.token, required this.userId});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String _language = 'en';

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_language == 'fr' ? 'Message vide' : 'Empty message')),
      );
      return;
    }

    setState(() {
      _messages.add({'sender': 'user', 'text': message, 'time': DateTime.now()});
      _messages.add({'sender': 'bot', 'text': '...', 'time': DateTime.now()});
      _isLoading = true;
    });

    _controller.clear();
    scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/chatbot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({'message': message}),
      );

      String reply = response.statusCode == 200
          ? json.decode(response.body)['reply'] ?? ''
          : (_language == 'fr' ? 'Erreur de réponse.' : 'Error: Could not get response');

      // Détection automatique de langue
      _language = reply.contains(RegExp(r'[éèàçù]')) ? 'fr' : 'en';

      // 1. Remplacer les montants précédés de € par DT
      reply = reply.replaceAllMapped(RegExp(r'€\s?(\d+(?:[.,]\d{1,2})?)'), (match) {
        return '${match.group(1)} DT';
      });

      // 2. Ajouter DT seulement aux montants qui sont précédés de " - ", "price", "prix", ou ":"
      reply = reply.replaceAllMapped(
        RegExp(
          r'(?<=\b(?:price|prix|-\s?)|:\s?)(\d{2,4}(?:[.,]\d{1,2})?)(?!\s?(cm|mm|g|DT|€|\d))',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)} DT',
      );

      setState(() {
        _messages.removeLast(); // retire "..."
        _messages.add({'sender': 'bot', 'text': reply, 'time': DateTime.now()});
        _isLoading = false;
      });

      scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({
          'sender': 'bot',
          'text': _language == 'fr' ? 'Erreur de connexion.' : 'Error: No connection',
          'time': DateTime.now()
        });
        _isLoading = false;
      });
      scrollToBottom();
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final time = (message['time'] as DateTime).toLocal();
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) CircleAvatar(child: Icon(Icons.smart_toy, size: 16)),
              SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blueAccent : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            timeStr,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputHint = _language == 'fr'
        ? 'Écrivez votre message...'
        : 'Type your message...';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _language == 'fr'
              ? 'Chatbot Magasin de Chaussures'
              : 'Shoe Store Chatbot',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Arrière-plan
          Positioned.fill(
            child: Image.network(
              'http://localhost:5000/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          // Chat UI
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return _buildMessage(message);
                  },
                ),
              ),
              if (_isLoading) LinearProgressIndicator(),
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: inputHint,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
