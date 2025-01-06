import 'dart:convert';
import 'dart:async';
import 'package:chatapp/Landing.dart';
import 'package:chatapp/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          fontFamily: 'RobotoMono',
        ),
        home: FutureBuilder<bool>(
          future: _checkLoginStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // or splash screen
            } else if (snapshot.hasData && snapshot.data == true) {
              return Landing_page();
            } else {
              return LoginPage();
            }
          },
        ),
      ),
    );
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token !=
        null; // Return true if token exists, meaning user is logged in
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadThreadContent();
  }

  Future<void> _loadThreadContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');

      if (userEmail != null) {
        final url = 'http://31.220.96.248:5002/getThreadContent/$userEmail';
        final response = await http.get(Uri.parse(url));
        print("${response.body} for $userEmail");

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          final threadContent = jsonResponse['thread_content'];

          if (threadContent != null && threadContent.isNotEmpty) {
            final chatProvider =
                Provider.of<ChatProvider>(context, listen: false);
            chatProvider.loadMessagesFromThreadContent(threadContent);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(); // Ensuring the scroll happens after the build
            });
          }
        } else {
          print('Failed to load thread content: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error loading thread content: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences

    // Clear the messages from the provider
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearMessages();

    setState(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(); // Ensuring scroll happens after each build
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatProvider.messages.length +
                  (chatProvider.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatProvider.messages.length &&
                    chatProvider.isTyping) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.01),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: screenSize.width * 0.02),
                        TypingIndicator(),
                      ],
                    ),
                  );
                }

                final message = chatProvider.messages[index];
                final isUserMessage = message.sender == 'You';
                return Row(
                  mainAxisAlignment: isUserMessage
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isUserMessage)
                      Container(
                        width: 30, // Adjust this to match the size you want
                        height: 40, // Adjust this to match the size you want
                        child: Image.asset(
                          "assets/images/My Sevak Logo Placeholder.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    SizedBox(width: screenSize.width * 0.02),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: screenSize.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        gradient: isUserMessage
                            ? LinearGradient(
                                colors: [Colors.blue[300]!, Colors.blue[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[500]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isUserMessage
                              ? const Radius.circular(12)
                              : const Radius.circular(0),
                          bottomRight: isUserMessage
                              ? const Radius.circular(0)
                              : const Radius.circular(12),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(screenSize.width * 0.03),
                      margin: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.01,
                          horizontal: screenSize.width * 0.02),
                      child: isUserMessage
                          ? _buildUserMessage(message, screenSize)
                          : _buildBotMessage(message, screenSize),
                    ),
                    if (isUserMessage)
                      const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenSize.width * 0.02),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.015,
                          horizontal: screenSize.width * 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenSize.width * 0.02),
                GestureDetector(
                  onTap: () async {
                    if (_controller.text.isNotEmpty) {
                      final chatProvider =
                          Provider.of<ChatProvider>(context, listen: false);
                      chatProvider.addMessage(_controller.text);
                      _controller.clear();

                      await chatProvider.fetchBotResponse();

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom(); // Scroll after bot response
                      });
                    }
                  },
                  child: const CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 164, 238, 122),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),

                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(Message message, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          message.text,
          style: TextStyle(
            color: Colors.black,
            fontSize: screenSize.width * 0.03,
          ),
        ),
        Text(
          _formatMessageTime(message.time),
          style: TextStyle(
            fontSize: screenSize.width * 0.03,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildBotMessage(Message message, Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: message.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontSize: screenSize.width * 0.03),
          ),
          onTapLink: (text, href, title) {
            if (href != null) {
              FlutterWebBrowser.openWebPage(
                url: href,
                customTabsOptions: const CustomTabsOptions(
                  colorScheme: CustomTabsColorScheme.dark,
                  toolbarColor: Colors.deepPurple,
                  secondaryToolbarColor: Colors.green,
                  navigationBarColor: Colors.amber,
                  addDefaultShareMenuItem: true,
                  instantAppsEnabled: true,
                  showTitle: true,
                  urlBarHidingEnabled: true,
                ),
                safariVCOptions: const SafariViewControllerOptions(
                  barCollapsingEnabled: true,
                  preferredBarTintColor: Colors.black,
                  preferredControlTintColor: Colors.white,
                  dismissButtonStyle:
                      SafariViewControllerDismissButtonStyle.close,
                  modalPresentationCapturesStatusBarAppearance: true,
                ),
              );
            }
          },
        ),
        Text(
          _formatMessageTime(message.time),
          style: TextStyle(
            fontSize: screenSize.width * 0.025,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    } else if (time.difference(now).inDays == -1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(time)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }
}

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  bool _isTyping = false;

  List<Message> get messages => _messages;
  bool get isTyping => _isTyping;

  void setIsTyping(bool value) {
    _isTyping = value;
    notifyListeners();
  }

  void addMessage(String text) {
    final userMessage = Message(
      id: Uuid().v4(),
      text: text,
      time: DateTime.now(),
      sender: 'You',
    );
    _messages.add(userMessage);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void loadMessagesFromThreadContent(String threadContent) {
    List<String> lines = threadContent.split('\n');
    String? currentSender;
    StringBuffer currentMessageBuffer = StringBuffer();

    for (var line in lines) {
      if (line.startsWith('User:') || line.startsWith('Assistant:')) {
        if (currentSender != null && currentMessageBuffer.isNotEmpty) {
          _messages.add(Message(
            id: Uuid().v4(),
            text: currentMessageBuffer.toString().trim(),
            time: DateTime.now(),
            sender: currentSender == 'User' ? 'You' : 'Bot',
          ));
          currentMessageBuffer.clear();
        }
        int separatorIndex = line.indexOf(':');
        currentSender = line.substring(0, separatorIndex).trim();
        currentMessageBuffer.write(line.substring(separatorIndex + 1).trim());
      } else {
        currentMessageBuffer.writeln(line.trim());
      }
    }

    if (currentSender != null && currentMessageBuffer.isNotEmpty) {
      _messages.add(Message(
        id: Uuid().v4(),
        text: currentMessageBuffer.toString().trim(),
        time: DateTime.now(),
        sender: currentSender == 'User' ? 'You' : 'Bot',
      ));
    }

    notifyListeners();
  }

  Future<void> fetchBotResponse() async {
    // Check if there is already a message in progress (isTyping).
    if (_isTyping) {
      return; // Exit early if bot is already typing.
    }

    setIsTyping(true); // Set bot as typing

    print("fetchBotResponse triggered");

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userEmail = prefs.getString('userEmail');
      final lastMessage = _messages.last;

      final response = await http.post(
        Uri.parse('http://31.220.96.248:5002/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': lastMessage.text,
          "userId": userId,
          "userEmail": userEmail,
        }),
      );

      print("API call completed with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        await Future.delayed(Duration(seconds: 2)); // Simulate typing delay

        final data = jsonDecode(response.body);
        final String? responseMessage = data['response'];
        print("Response received: $responseMessage");

        if (responseMessage != null) {
          final botMessage = Message(
            id: Uuid().v4(),
            text: responseMessage,
            time: DateTime.now(),
            sender: 'Bot',
          );

          // Ensure the message is only added once
          if (!_messages.contains(botMessage)) {
            _messages.add(botMessage);
          }

          setIsTyping(false);
          notifyListeners();
        } else {
          print('No response message in API response');
        }
      } else {
        print('Failed to fetch from API. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bot response: $e');
    } finally {
      setIsTyping(false);
    }
  }

  void deleteMessage(String id) {
    final index = _messages.indexWhere((message) => message.id == id);
    if (index >= 0) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }
}

class Message {
  final String id;
  final String text;
  final DateTime time;
  final String sender;

  Message({
    required this.id,
    required this.text,
    required this.time,
    required this.sender,
  });
}

// This widget animates the "bot is typing..." indicator
class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(_controller!);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation!.value * (index == 1 ? -1 : 1)),
          child: CircleAvatar(
            radius: 3,
            backgroundColor: Colors.grey[600],
          ),
        );
      },
    );
  }
}
