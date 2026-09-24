import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../services/storage_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _testing = false;
  String? _testStatus;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _testing = true;
      _testStatus = null;
    });

    try {
      final uri = Uri.parse(url.endsWith('/') ? '${url}api/auth/login/' : '$url/api/auth/login/');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      // HTTP 405 (Method Not Allowed) or 200 means the Django backend responded!
      if (res.statusCode == 405 || res.statusCode == 200 || res.statusCode == 400) {
        setState(() {
          _testSuccess = true;
          _testStatus = 'Connected successfully to backend!';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testStatus = 'Server responded with code ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testStatus = 'Could not reach server. Verify backend is running and USB/Wi-Fi is connected.';
      });
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _saveAndClose() async {
    final url = _controller.text.trim();
    if (url.isNotEmpty) {
      await StorageService.saveCustomBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend URL set to: $url'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.dns_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Server Configuration', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select or enter the backend URL your mobile device will connect to:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Backend Base URL',
                hintText: 'http://127.0.0.1:8000',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reset to default',
                  onPressed: () => setState(() => _controller.text = 'http://127.0.0.1:8000'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('127.0.0.1:8000 (USB/ADB)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _controller.text = 'http://127.0.0.1:8000'),
                ),
                ActionChip(
                  label: const Text('10.24.207.60:8000 (Wi-Fi)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _controller.text = 'http://10.24.207.60:8000'),
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8000 (Emulator)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _controller.text = 'http://10.0.2.2:8000'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: Text(_testing ? 'Testing...' : 'Test Connection'),
            ),
            if (_testStatus != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _testSuccess ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _testStatus!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _testSuccess ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAndClose,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
