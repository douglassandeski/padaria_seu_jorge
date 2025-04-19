import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class GravadorView extends StatefulWidget {
  const GravadorView({super.key});

  @override
  State<GravadorView> createState() => _GravadorViewState();
}

class _GravadorViewState extends State<GravadorView> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textoReconhecido = 'Toque no microfone e fale...';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _iniciarOuPararGravacao() async {
    if (!_isListening) {
      bool disponivel = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (erro) => print('Erro: $erro'),
      );

      if (disponivel) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (resultado) {
            setState(() {
              _textoReconhecido = resultado.recognizedWords;
            });
          },
          listenFor: Duration(seconds: 30), // Define o tempo de escuta, por exemplo, 30 segundos.
          pauseFor: Duration(seconds: 5), // Define o tempo de pausa entre as palavras.
          localeId: 'pt_BR', // Configura o idioma para português.
        );
      } else {
        setState(() => _textoReconhecido = 'Erro ao iniciar o reconhecimento de voz.');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Gravar Voz'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _textoReconhecido,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FloatingActionButton(
              onPressed: _iniciarOuPararGravacao,
              backgroundColor: Colors.brown,
              child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}