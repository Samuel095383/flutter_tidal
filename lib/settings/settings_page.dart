import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialBaseUrl,
    required this.onSaved,
  });

  final String initialBaseUrl;
  final Future<void> Function(String baseUrl) onSaved;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBaseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeBaseUrl(String input) {
    var v = input.trim();
    if (v.endsWith('/')) v = v.substring(0, v.length - 1);
    return v;
  }

  Future<void> _save() async {
    final normalized = _normalizeBaseUrl(_controller.text);

    if (normalized.isEmpty) {
      setState(() => _error = 'Please enter a base URL.');
      return;
    }

    final toStore = normalized.startsWith('http') ? normalized : 'http://$normalized';

    setState(() => _error = null);
    await widget.onSaved(toStore);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.10:8000',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}