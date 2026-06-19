import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';

void main() {
  runApp(const VoiceMessageExampleApp());
}

class VoiceMessageExampleApp extends StatelessWidget {
  const VoiceMessageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Message UI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const VoiceMessageDemoPage(),
    );
  }
}

class VoiceMessageDemoPage extends StatefulWidget {
  const VoiceMessageDemoPage({super.key});

  @override
  State<VoiceMessageDemoPage> createState() => _VoiceMessageDemoPageState();
}

class _VoiceMessageDemoPageState extends State<VoiceMessageDemoPage> {
  final VoiceRecordController _recordController = VoiceRecordController();
  final List<_VoiceMessage> _messages = [
    _VoiceMessage(
      id: 'seed-1',
      audioPath: '',
      duration: const Duration(seconds: 8),
      waveform: _mockWaveform(seed: 1),
      isSent: false,
    ),
    _VoiceMessage(
      id: 'seed-2',
      audioPath: '',
      duration: const Duration(seconds: 14),
      waveform: _mockWaveform(seed: 2),
      isSent: true,
    ),
  ];

  @override
  void dispose() {
    _recordController.dispose();
    super.dispose();
  }

  void _addRecordedMessage(String path, Duration duration) {
    setState(() {
      _messages.add(
        _VoiceMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          audioPath: path,
          duration: duration,
          waveform: _mockWaveform(seed: path.hashCode),
          isSent: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Message UI'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final hasAudio = message.audioPath.isNotEmpty;
        
                  if (!hasAudio) {
                    return Opacity(
                      opacity: 0.55,
                      child: VoiceMessageBubble(
                        messageId: message.id,
                        audioPath: message.audioPath,
                        duration: message.duration,
                        waveform: message.waveform,
                        isSent: message.isSent,
                      ),
                    );
                  }
        
                  return VoiceMessageBubble(
                    messageId: message.id,
                    audioPath: message.audioPath,
                    duration: message.duration,
                    waveform: message.waveform,
                    isSent: message.isSent,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VoiceMessageRecorder(
                    controller: _recordController,
                    onRecordingComplete: _addRecordedMessage,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Record a message, then tap send to add it to the chat.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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

class _VoiceMessage {
  const _VoiceMessage({
    required this.id,
    required this.audioPath,
    required this.duration,
    required this.waveform,
    required this.isSent,
  });

  final String id;
  final String audioPath;
  final Duration duration;
  final List<double> waveform;
  final bool isSent;
}

List<double> _mockWaveform({required int seed, int length = 48}) {
  final random = Random(seed);
  return List<double>.generate(
    length,
    (_) => random.nextDouble(),
  );
}
