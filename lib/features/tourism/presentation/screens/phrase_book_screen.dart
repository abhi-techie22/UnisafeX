import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhraseBookScreen extends StatelessWidget {
  const PhraseBookScreen({super.key});

  static const phrases = [
    ('Hello', 'नमस्ते', 'Namaste'),
    ('Thank you', 'धन्यवाद', 'Dhanyavaad'),
    ('Help me', 'मेरी मदद कीजिए', 'Meri madad kijiye'),
    ('Police', 'पुलिस', 'Police'),
    ('Hospital', 'अस्पताल', 'Aspataal'),
    ('How much?', 'कितना है?', 'Kitna hai?'),
    ('Where is...?', '...कहाँ है?', '...kahaan hai?'),
    ('I need a taxi', 'मुझे टैक्सी चाहिए', 'Mujhe taxi chahiye'),
    ('I am lost', 'मैं रास्ता भूल गया हूँ', 'Main raasta bhool gaya hoon'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Phrase Book')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: phrases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              title: Text(phrase.$1),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text('${phrase.$2}\n${phrase.$3}'),
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Copy phrase',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phrase.$2));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hindi phrase copied')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
