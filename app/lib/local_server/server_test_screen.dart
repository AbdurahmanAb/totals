import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'server_service.dart';

class ServerTestScreen extends StatefulWidget {
  const ServerTestScreen({super.key});

  @override
  State<ServerTestScreen> createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends State<ServerTestScreen> {
  final ServerService _serverService = ServerService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serverService.stopServer();
    _serverService.dispose();
    super.dispose();
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_serverService.isRunning) {
        await _serverService.stopServer();
      } else {
        await _serverService.startServer();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Server Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _serverService.isRunning
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          _serverService.isRunning ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _serverService.isRunning
                          ? 'Server Running'
                          : 'Server Stopped',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_serverService.isRunning) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Local URL:',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _serverService.serverUrl ?? 'Unknown',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_serverService.serverUrl != null) {
                            Clipboard.setData(
                                ClipboardData(text: _serverService.serverUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('URL copied to clipboard')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy URL'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Control Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _toggleServer,
              style: FilledButton.styleFrom(
                backgroundColor:
                    _serverService.isRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_serverService.isRunning
                      ? Icons.stop_circle
                      : Icons.play_circle),
              label: Text(
                _serverService.isRunning ? 'Stop Server' : 'Start Server',
                style: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Start the server.\n'
              '2. Copy the URL.\n'
              '3. Open a browser on this device or another device on the same Wi-Fi.\n'
              '4. Paste the URL to see the test page.',
            ),
          ],
        ),
      ),
    );
  }
}
