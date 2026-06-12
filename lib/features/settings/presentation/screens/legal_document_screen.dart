import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen.privacy({super.key})
      : title = 'Privacy Policy',
        sections = _privacySections;

  const LegalDocumentScreen.terms({super.key})
      : title = 'Terms of Service',
        sections = _termsSections;

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 36),
        children: [
          Text(
            'Effective 11 June 2026',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.$1,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  Text(section.$2, style: const TextStyle(height: 1.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _privacySections = [
    (
      'Information you provide',
      'UniSafeX stores account and optional travel-profile details such as '
          'name, nationality, current location, passport country, visa type '
          'and travel purpose in Supabase for your signed-in account.',
    ),
    (
      'Location',
      'Precise location is requested only to show nearby destinations and '
          'calculate distances. A manually selected location may be used '
          'instead. Location is not written to your profile unless you enter '
          'it in the profile form.',
    ),
    (
      'How data is used',
      'Data supports profile display, personalization, saved places and core '
          'travel features. UniSafeX does not sell personal profile data.',
    ),
    (
      'Security and control',
      'Supabase Row Level Security restricts profile records to the signed-in '
          'user. You should protect your device and account credentials.',
    ),
    (
      'Contact',
      'Questions, issue reports or deletion requests can be submitted through '
          'the UniSafeX GitHub issue tracker linked from Help & Support.',
    ),
  ];

  static const _termsSections = [
    (
      'Travel information',
      'Destination details, prices, opening times, safety scores, currency '
          'rates and assistant responses are informational and may change. '
          'Verify critical information with official sources.',
    ),
    (
      'Safety',
      'No destination or activity can be guaranteed safe. Follow local laws, '
          'official warnings and emergency instructions. Call 112 in India '
          'when immediate assistance is required.',
    ),
    (
      'Acceptable use',
      'Do not misuse the service, attempt unauthorized access, or submit '
          'fraudulent information. Features may be updated or withdrawn.',
    ),
    (
      'Limitation',
      'UniSafeX is not responsible for decisions made solely from estimated '
          'or third-party travel information.',
    ),
  ];
}
