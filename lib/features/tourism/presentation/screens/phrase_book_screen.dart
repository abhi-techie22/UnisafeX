import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhraseBookScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('local_phrase_book'.tr())),
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
              title: Text(phrase.$1.tr()),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text('${phrase.$2}\n${phrase.$3}'),
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'copy_phrase'.tr(),
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phrase.$2));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('phrase_copied'.tr())),
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
