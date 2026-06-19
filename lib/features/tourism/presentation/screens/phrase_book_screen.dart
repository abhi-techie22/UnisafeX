import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PhraseBookScreen extends StatefulWidget {
  const PhraseBookScreen({super.key});

  static const phrases = [
    ('hello', 'नमस्ते', 'Namaste'),
    ('thank_you', 'धन्यवाद', 'Dhanyavaad'),
    ('help_me', 'मेरी मदद कीजिए', 'Meri madad kijiye'),
    ('police', 'पुलिस', 'Police'),
    ('hospital', 'अस्पताल', 'Aspataal'),
    ('how_much', 'कितना है?', 'Kitna hai?'),
    ('where_is', '...कहाँ है?', '...kahaan hai?'),
    ('need_taxi', 'मुझे टैक्सी चाहिए', 'Mujhe taxi chahiye'),
    ('i_am_lost', 'मैं रास्ता भूल गया हूँ', 'Main raasta bhool gaya hoon'),
  ];

  @override
  State<PhraseBookScreen> createState() => _PhraseBookScreenState();
}

class _PhraseBookScreenState extends State<PhraseBookScreen> {
  late final FlutterTts _tts;
  String? _speakingPhrase;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('hi-IN');
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingPhrase = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speakingPhrase = null);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('local_phrase_book'.tr())),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: PhraseBookScreen.phrases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final phrase = PhraseBookScreen.phrases[index];
          final isSpeaking = _speakingPhrase == phrase.$2;
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              title: Text(phrase.$1.tr()),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text('${phrase.$2}\n${phrase.$3}'),
              ),
              isThreeLine: true,
              trailing: SizedBox(
                width: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Speak Hindi phrase',
                      icon: Icon(
                        isSpeaking
                            ? Icons.volume_up_rounded
                            : Icons.volume_up_outlined,
                      ),
                      onPressed: () => _speak(phrase.$2),
                    ),
                    IconButton(
                      tooltip: 'copy_phrase'.tr(),
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phrase.$2));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('phrase_copied'.tr())),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _speak(String phrase) async {
    try {
      await _tts.stop();
      setState(() => _speakingPhrase = phrase);
      await _tts.speak(phrase);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speakingPhrase = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio is not available on this device.')),
      );
    }
  }
}
