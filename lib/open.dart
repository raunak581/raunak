import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenAIChatService {
  final String apiKey =
      "sk-proj-AkmIKHdVDqbAp9gXn532T3BlbkFJNbplxEIwrrRl2dCHBqCY";
  final String assistantId = "asst_v723GyN0btxPD3R6usGhk6LU";
  final String threadIdStorageKey = "threadId";

  Future<String?> getExistingThreadId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(threadIdStorageKey);
  }

  Future<void> saveThreadId(String threadId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(threadIdStorageKey, threadId);
  }

  Future<String?> startOrGetThread(String content) async {
    String? threadId = await getExistingThreadId();
    if (threadId != null) {
      print("Existing thread found: $threadId");
    } else {
      print("No existing thread found. Creating a new thread and run.");
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/threads'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'assistant_id': assistantId,
          'thread': {
            'messages': [
              {'role': 'user', 'content': content}
            ],
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        threadId = data['thread_id'];
        await saveThreadId(threadId!);
      } else {
        throw Exception("Failed to create a new thread");
      }
    }
    return threadId;
  }

  Future<void> sendMessage(String threadId, String content) async {
    // Send user message
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role': 'user',
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      print("User message sent.");
    } else {
      throw Exception("Failed to send message");
    }

    // Trigger a new run
    final runResponse = await http.post(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/runs'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'assistant_id': assistantId}),
    );

    if (runResponse.statusCode == 200) {
      print("Run triggered.");
    } else {
      throw Exception("Failed to trigger run");
    }
  }

  Future<String?> getAssistantResponse(String threadId) async {
    final response = await http.get(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = data['data'] as List;

      final assistantMessage =
          messages.where((message) => message['role'] == 'assistant').toList();

      if (assistantMessage.isNotEmpty) {
        return assistantMessage.last['content'];
      } else {
        print("No assistant response found.");
        return null;
      }
    } else {
      throw Exception("Failed to retrieve messages");
    }
  }

  Future<String?> chatWithAssistant(String content) async {
    final threadId = await startOrGetThread(content);

    if (threadId != null) {
      await sendMessage(threadId, content);
      final response = await getAssistantResponse(threadId);
      return response;
    }
    return null;
  }
}
