import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _category = 'suggestion';
  int _rating = 0;

  static const _categories = {
    'bug': 'Bug Report',
    'suggestion': 'Feature Suggestion',
    'ui': 'UI/UX Feedback',
    'performance': 'Performance Issue',
    'other': 'Other',
  };

  Future<void> _submit() async {
    if (_messageCtrl.text.trim().isEmpty) {
      showErrorSnack(context, 'Please enter your feedback');
      return;
    }
    final ticket = {
      'id': const Uuid().v4(),
      'category': _category,
      'rating': _rating,
      'message': _messageCtrl.text,
      'email': _emailCtrl.text,
      'ts': DateTime.now().toIso8601String(),
    };
    final box = Hive.box<dynamic>('feedback');
    await box.add(ticket);

    if (!mounted) return;
    showSuccessSnack(context, 'Thank you for your feedback!');

    // Also offer to send via email
    final emailUri = Uri.parse(
      'mailto:support@productchat.app?subject=Feedback: ${_categories[_category]}&body=${Uri.encodeComponent(_messageCtrl.text)}',
    );
    if (await canLaunchUrl(emailUri)) {
      // Ask user if they want to send via email too
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your feedback helps us improve',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          const Text('Category', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppColors.surfaceAlt,
            decoration: const InputDecoration(),
            items: _categories.entries.map((e) => DropdownMenuItem(
              value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 20),
          const Text('Rate your experience', style: TextStyle(
            color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              icon: Icon(
                i < _rating ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 32,
              ),
              onPressed: () => setState(() => _rating = i + 1),
            )),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _messageCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Your message',
              hintText: 'Describe your feedback in detail...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'you@example.com',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Submit'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
