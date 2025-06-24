import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, String>> _faqData = const [
    {
      'question': 'What is SilentSOS+?',
      'answer':
      'SilentSOS+ is an emergency alert app designed to help users silently request help in public or personal danger situations using features like stealth mode, voice-activated triggers, and fake call exits.'
    },
    {
      'question': 'How do I send an SOS alert?',
      'answer':
      'Just tap the main SOS button on the home screen. Your location and alert type will automatically be sent to emergency contacts or responders.'
    },
    {
      'question': 'What is the disguised UI mode?',
      'answer':
      'Disguised UI allows the app to appear as something else (like a calculator or gallery) to hide its true purpose in dangerous situations.'
    },
    {
      'question': 'Is my data safe?',
      'answer':
      'Yes. Your data is stored securely using Firebase Authentication and Firestore with strict access rules to protect your privacy.'
    },
    {
      'question': 'Can I cancel an SOS alert?',
      'answer':
      'Yes. If you trigger an alert by mistake, you can enter your PIN to cancel it immediately—provided your device hasn’t locked.'
    },
    {
      'question': 'Who are the responders?',
      'answer':
      'Responders can be verified hospital personnel or volunteers (NGOs, medics, security personnel) who receive your alert if they are nearby and available.'
    },
    {
      'question': 'I forgot my PIN. What do I do?',
      'answer':
      'Unfortunately, we don’t support PIN recovery yet. You’ll need to reset your account or contact support via email.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('FAQs'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A5ACD),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _faqData.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final faq = _faqData[index];
          return ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.purple[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              faq['question']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: [
              Text(
                faq['answer']!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              )
            ],
          );
        },
      ),
    );
  }
}
