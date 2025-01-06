import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:chatapp/Landing.dart';
import 'package:chatapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as flutter_sound;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class audioScreen extends StatefulWidget {
  const audioScreen({super.key});

  @override
  _audioScreenState createState() => _audioScreenState();
}

class _audioScreenState extends State<audioScreen> {
  WebSocket? _webSocket;
  final flutter_sound.FlutterSoundRecorder _recorder =
      flutter_sound.FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final int batchSize = 2; // Number of chunks per batch
  bool _isPlaying = false;
  bool _recorderInitialized = false;
  bool _isRecording = false;
  String transcript = "";
  final Queue<List<int>> _audioQueue =
      Queue<List<int>>(); // Queue for immediate playback
  final StreamController<List<int>> _audioStreamController = StreamController();
  String? _currentResponseId; // Store the current response ID
  final List<List<int>> _bufferedChunks = []; // Buffer for audio chunks

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    connectToWebSocket();

    _audioStreamController.stream.listen((chunk) async {
      List<int> wavData = addWavHeader(chunk);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/audio_chunk_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(wavData);

      // Set and play the chunk immediately
      await _audioPlayer.setFilePath(tempFile.path);
      await _audioPlayer.play();
    });
  }

  Future<void> _initializeAudio() async {
    await _requestPermissions();
    try {
      await _recorder.openRecorder();
      _recorderInitialized = true;
    } catch (e) {
      print("Failed to initialize recorder: $e");
    }
  }

  Future<void> _requestPermissions() async {
    var statusMicrophone = await Permission.microphone.request();
    if (statusMicrophone != PermissionStatus.granted) {
      print("Microphone permission not granted.");
    }
    var statusStorage = await Permission.storage.request();
    if (statusStorage != PermissionStatus.granted) {
      print("Storage permission not granted.");
    }
  }

  Map<String, dynamic> session = {
    "event_id": "event_123",
    "type": "session.update",
    "session": {
      "modalities": ["text", "audio"],
      "instructions":
          "You are an expert and have real time acess t0 everything and if there is no voice then you should tell the latest new or latest thing happens in last 24 hours",
      "voice": "echo",
      "input_audio_format": "pcm16",
      "output_audio_format": "pcm16",
      "input_audio_transcription": {"model": "whisper-1"},
      "turn_detection": {
        "type": "server_vad",
        "threshold": 0.5,
        "prefix_padding_ms": 300,
        "silence_duration_ms": 500
      },
      "tools": [
        {
          "type": "function",
          "name": "get_weather",
          "description":
              "Retrieves current weather information for a specified location",
          "strict": true,
          "parameters": {
            "type": "object",
            "required": ["location", "units"],
            "properties": {
              "location": {
                "type": "string",
                "description":
                    "The name of the location or geographic coordinates (latitude, longitude)"
              },
              "units": {
                "type": "string",
                "description":
                    "The unit of measurement for the temperature (e.g., metric, imperial)",
                "enum": ["metric", "imperial"]
              }
            },
            "additionalProperties": false
          }
        }
      ],
      "tool_choice": "auto",
      "temperature": 0.8,
      "max_response_output_tokens": "inf"
    }
  };

  Map<String, dynamic> started = {
    "event_id": "event_345",
    "type": "conversation.item.create",
    "previous_item_id": null,
    "item": {
      "id": "msg_001",
      "type": "message",
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text":
              "always greet"
        }
      ]
    }
  };

  List<int> addWavHeader(List<int> pcmData,
      {int sampleRate = 24000, int channels = 1}) {
    int byteRate = sampleRate * channels * 2;
    int totalDataLen = pcmData.length + 36;

    List<int> header = [
      0x52,
      0x49,
      0x46,
      0x46,
      totalDataLen & 0xff,
      (totalDataLen >> 8) & 0xff,
      (totalDataLen >> 16) & 0xff,
      (totalDataLen >> 24) & 0xff,
      0x57,
      0x41,
      0x56,
      0x45,
      0x66,
      0x6d,
      0x74,
      0x20,
      16,
      0,
      0,
      0,
      1,
      0,
      channels,
      0,
      sampleRate & 0xff,
      (sampleRate >> 8) & 0xff,
      (sampleRate >> 16) & 0xff,
      (sampleRate >> 24) & 0xff,
      byteRate & 0xff,
      (byteRate >> 8) & 0xff,
      (byteRate >> 16) & 0xff,
      (byteRate >> 24) & 0xff,
      (channels * 2),
      0,
      16,
      0,
      0x64,
      0x61,
      0x74,
      0x61,
      pcmData.length & 0xff,
      (pcmData.length >> 8) & 0xff,
      (pcmData.length >> 16) & 0xff,
      (pcmData.length >> 24) & 0xff
    ];

    return header + pcmData;
  }

  @override
  void dispose() {
    _webSocket?.close();
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  void connectToWebSocket() async {
    try {
      _webSocket = await WebSocket.connect('ws://31.220.96.248:8080');
      _webSocket?.listen((data) {
        _handleWebSocketMessage(data);
      }, onDone: () {
        print('WebSocket connection closed.');
      }, onError: (error) {
        print('WebSocket error: $error');
      });
      print('Connected to WebSocket server.');
      _webSocket?.add(jsonEncode(session));
      _webSocket?.add(jsonEncode(started));
      _webSocket?.add(jsonEncode({'type': "response.create"}));
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

// void _handleWebSocketMessage(dynamic data) async {
//     if (data is String) {
//       try {
//         final Map<String, dynamic> messageData = jsonDecode(data);
//         print(messageData);

//         if (messageData['type'] == "response.audio.delta") {
//           print("response $messageData['response_id']");
//           List<int> decodedBytes = base64.decode(messageData['delta']);
//           if (decodedBytes.isNotEmpty) {
//             _bufferedChunks.add(decodedBytes); // Add to the buffer
//           //    if (_isPlaying) {
//           //   await _audioPlayer.stop();
//           // }
//           // _playBufferedAudio();

//             // Start playback if enough chunks are buffered
//             if (!_isPlaying && _bufferedChunks.length >= 2) {
//               _playBufferedAudio();
//             }
//           }
//         }
//       } catch (e) {
//         print('Error parsing WebSocket message: $e');
//       }
//     }
//   }

  void _handleWebSocketMessage(dynamic data) async {
    if (data is String) {
      try {
        final Map<String, dynamic> messageData = jsonDecode(data);
        print(messageData);

        if (messageData['type'] == "response.audio.delta") {
          String newResponseId = messageData['response_id'];

          // Check if the new response ID is different from the current one
          if (newResponseId != _currentResponseId) {
            // If different, update the current response ID, clear the buffer, and stop any playback
            _currentResponseId = newResponseId;
            _bufferedChunks.clear();
            if (_isPlaying) {
              await _audioPlayer.stop(); // Stop current playback
              _isPlaying = false;
            }
          }

          List<int> decodedBytes = base64.decode(messageData['delta']);
          if (decodedBytes.isNotEmpty) {
            _bufferedChunks.add(decodedBytes); // Add new chunks to the buffer

            // Start playback if enough chunks are buffered
            if (!_isPlaying && _bufferedChunks.isNotEmpty) {
              _playBufferedAudio();
            }
          }
        }
      } catch (e) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  Future<void> _playBufferedAudio() async {
    _isPlaying = true;

    try {
      // Concatenate all buffered chunks into one continuous byte list
      List<int> combinedChunks =
          _bufferedChunks.expand((chunk) => chunk).toList();
      List<int> wavData = addWavHeader(combinedChunks);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/combined_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(wavData);

      // Clear the buffer after combining the chunks
      _bufferedChunks.clear();

      // Stop any ongoing playback before playing the concatenated audio
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      // Play the new audio immediately
      await _audioPlayer.setFilePath(tempFile.path);
      await _audioPlayer.play();

      // Wait until playback is complete
      await _audioPlayer.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed);
    } catch (e) {
      print("Error playing combined audio: $e");
    } finally {
      _isPlaying = false;
      // Check if there are more chunks queued after playback
      if (_bufferedChunks.isNotEmpty) {
        _playBufferedAudio();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Handle back button
        if (_isRecording) {
          // Stop recording before navigating back
          await _recorder.stopRecorder();
          setState(() {
            _isRecording = false;
          });
        }
        return true; // Allow popping the page
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Real-Time Audio Chat')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
             if (_audioPlayer.playing) {
              await _audioPlayer.stop(); // Stop audio playback
            }

            if (_isRecording) {
              // Stop recording before navigating back
              await _recorder.stopRecorder();
              setState(() {
                _isRecording = false;
              });
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const Landing_page()),
            );
          },
            
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: transcript,
                    selectable: true,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: sendAudioMessage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> sendAudioMessage() async {
    if (!_recorderInitialized) {
      print("Recorder not initialized.");
      return;
    }

    if (_isRecording) {
      String? path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        File audioFile = File(path);
        Uint8List audioBytes = await audioFile.readAsBytes();
        String base64Audio = base64Encode(audioBytes);

        Map<String, dynamic> audioMessage = {
          "type": "input_audio_buffer.append",
          "audio": base64Audio
        };

        Map<String, dynamic> started = {
          "event_id": "event_345",
          "type": "conversation.item.create",
          "previous_item_id": null,
          "item": {
            "id": "msg_001",
            "type": "message",
            "role": "user",
            "content": [
              {"type": "input_text", "text": "Hello, how are you?"}
            ]
          }
        };

        _webSocket?.add(jsonEncode(audioMessage));
        _webSocket?.add(jsonEncode({'type': "input_audio_buffer.commit"}));
        _webSocket?.add(jsonEncode({'type': "response.create"}));
      }
    } else {
      Directory tempDir = await getApplicationDocumentsDirectory();
      String path = '${tempDir.path}/audio_message.wav';
      await _recorder.startRecorder(
        toFile: path,
        codec: flutter_sound.Codec.pcm16WAV,
        sampleRate: 24000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
      });
    }
  }
}
