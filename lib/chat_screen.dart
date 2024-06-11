import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File class
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality
import 'package:image_picker/image_picker.dart'; // Import for image picker

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  TextEditingController _userInput = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const apiKey = "AIzaSyAtdzR0CsiWxiVZ0ERYbRczZoDgME3Z3eo"; // Replace with your actual API key
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  final List<Message> _messages = [];

  Future<void> sendMessage(String message, {File? image}) async {
    if (message.isEmpty && image == null) return;

    final newMessage = Message(
      isUser: true,
      message: message,
      date: DateTime.now(),
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
      image: image,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _userInput.clear();
    newMessage.animationController.forward();

    try {
      String contentMessage = message;

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        contentMessage += "\n\n![Image](data:image/jpeg;base64,$base64Image)";
      }

      final content = [Content.text(contentMessage)];

      final response = await model.generateContent(content);

      final responseMessage = Message(
        isUser: false,
        message: response.text ?? "Failed to get response from server.",
        date: DateTime.now(),
        animationController: AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: this,
        ),
      );

      setState(() {
        _messages.add(responseMessage);
      });

      responseMessage.animationController.forward();
    } catch (e) {
      final errorMessage = Message(
        isUser: false,
        message: 'Failed to get response from server. Error: $e',
        date: DateTime.now(),
        animationController: AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: this,
        ),
      );

      setState(() {
        _messages.add(errorMessage);
      });

      errorMessage.animationController.forward();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await sendMessage('', image: imageFile);
    }
  }

  @override
  void dispose() {
    for (var message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.dstATop),
            image: NetworkImage(
                "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEigDbiBM6I5Fx1Jbz-hj_mqL_KtAPlv9UsQwpthZIfFLjL-hvCmst09I-RbQsbVt5Z0QzYI_Xj1l8vkS8JrP6eUlgK89GJzbb_P-BwLhVP13PalBm8ga1hbW5pVx8bswNWCjqZj2XxTFvwQ__u4ytDKvfFi5I2W9MDtH3wFXxww19EVYkN8IzIDJLh_aw/s1920/space-soldier-ai-wallpaper-4k.webp"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(
                    message: message,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    flex: 15,
                    child: TextFormField(
                      style: TextStyle(color: Colors.white),
                      controller: _userInput,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black54,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        labelText: 'Enter Your Message',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    padding: EdgeInsets.all(12),
                    iconSize: 30,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.black),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(CircleBorder()),
                    ),
                    onPressed: () {
                      if (_userInput.text.isNotEmpty) {
                        sendMessage(_userInput.text);
                      }
                    },
                    icon: Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  final AnimationController animationController;
  final File? image;

  Message({
    required this.isUser,
    required this.message,
    required this.date,
    required this.animationController,
    this.image,
  });
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(message.isUser ? 1.0 : -1.0, 0.0),
        end: Offset(0.0, 0.0),
      ).animate(CurvedAnimation(
        parent: message.animationController,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: message.animationController,
          curve: Curves.easeIn,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(15),
          margin: EdgeInsets.symmetric(vertical: 5).copyWith(
            left: message.isUser ? 100 : 10,
            right: message.isUser ? 10 : 100,
          ),
          decoration: BoxDecoration(
            color: message.isUser ? Colors.deepPurple : Colors.purpleAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: message.isUser ? Radius.circular(10) : Radius.zero,
              topRight: Radius.circular(10),
              bottomRight: message.isUser ? Radius.zero : Radius.circular(10),
            ),
          ),
          child: Row(
            children: [
              if (message.image != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Image.file(
                    message.image!,
                    width: 50,
                    height: 50,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        DateFormat('HH:mm').format(message.date),
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              if (!message.isUser)
                IconButton(
                  icon: Icon(Icons.copy, color: Colors.white70),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
